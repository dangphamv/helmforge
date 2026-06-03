#!/usr/bin/env bash
# ============================================================================
#  preflight.sh — Verify the environment is RUNNABLE before agents write code
# ----------------------------------------------------------------------------
#  Answers: can this repo install/build/test/typecheck on this machine?
#  /sdlc calls this before the implement phase. If the BASELINE is already broken
#  (not the agent), the pipeline STOPS and tells the human instead of blaming new code.
#
#  Exit codes: 0 = baseline OK · 2 = baseline broken · 3 = undetermined
# ============================================================================
set -uo pipefail
cd "$(dirname "$0")/../.." 2>/dev/null || true

if [ -t 1 ]; then G=$(printf '\033[32m'); R=$(printf '\033[31m'); Y=$(printf '\033[33m'); D=$(printf '\033[2m'); RST=$(printf '\033[0m'); else G=""; R=""; Y=""; D=""; RST=""; fi
ok(){ printf "%s✓%s %s\n" "$G" "$RST" "$*"; }
no(){ printf "%s✗%s %s\n" "$R" "$RST" "$*"; }
wn(){ printf "%s!%s %s\n" "$Y" "$RST" "$*"; }
hd(){ printf "\n%s== %s ==%s\n" "$D" "$*" "$RST"; }

FAIL=0; UNKNOWN=0

# ---- detect package manager + run a command if the script exists -----------
PM=""
[ -f pnpm-lock.yaml ] && PM=pnpm
[ -f yarn.lock ] && PM=yarn
[ -f package-lock.json ] && PM=npm
[ -f bun.lockb ] && PM=bun

has_script(){ [ -f package.json ] && grep -q "\"$1\"[[:space:]]*:" package.json; }
run(){ # run <label> <cmd...>
  local label="$1"; shift
  hd "$label"
  printf "%s\$ %s%s\n" "$D" "$*" "$RST"
  if "$@"; then ok "$label OK"; else no "$label FAIL"; FAIL=1; fi
}

# ---- 1. toolchain ----------------------------------------------------------
hd "Toolchain"
for b in git node; do command -v "$b" >/dev/null 2>&1 && ok "$b $($b --version 2>/dev/null | head -1)" || { no "$b missing"; FAIL=1; }; done
if [ -n "$PM" ]; then command -v "$PM" >/dev/null 2>&1 && ok "package manager: $PM" || { no "$PM missing (repo uses $PM)"; FAIL=1; }; else wn "No JS lockfile detected — could be a Python/Go/other repo"; fi

# ---- 2. dependencies installed --------------------------------------------
if [ -f package.json ]; then
  if [ -d node_modules ]; then ok "node_modules present"
  else
    wn "Deps not installed — try:"
    case "$PM" in
      pnpm) run "install" pnpm install --frozen-lockfile || true;;
      yarn) run "install" yarn install --frozen-lockfile || true;;
      npm)  run "install" npm ci || true;;
      bun)  run "install" bun install || true;;
      *)    wn "Unknown PM for installing deps"; UNKNOWN=1;;
    esac
  fi
fi
# python
[ -f requirements.txt ] && { command -v pip >/dev/null && ok "pip present" || wn "requirements.txt present but pip missing"; }
[ -f pyproject.toml ] && { command -v poetry >/dev/null && ok "poetry present" || wn "pyproject.toml present — check poetry/uv"; }

# ---- 3. typecheck / lint / build / test (run only what the repo has) ------
if [ -f package.json ]; then
  has_script typecheck && run "typecheck" $PM run typecheck || wn "no 'typecheck' script (skip)"
  has_script lint      && run "lint"      $PM run lint      || wn "no 'lint' script (skip)"
  has_script build     && run "build"     $PM run build     || wn "no 'build' script (skip)"
  if has_script test; then run "test" $PM run test; else wn "no 'test' script (skip)"; UNKNOWN=1; fi
else
  wn "No package.json — run your language's test/build commands (pytest, go test, mvn...) manually."
  UNKNOWN=1
fi

# ---- 4. database reachable (if there are signs a DB is needed) ------------
hd "Database"
if [ -f docker-compose.yml ] || [ -f docker-compose.yaml ] || [ -f compose.yaml ]; then
  if command -v docker >/dev/null 2>&1; then
    if docker compose ps >/dev/null 2>&1 && docker compose ps 2>/dev/null | grep -qi "up\|running"; then ok "docker compose running"
    else wn "docker-compose present but services not up. Run: docker compose up -d"; fi
  else wn "docker-compose present but docker missing."; fi
fi
if [ -n "${DATABASE_URL:-}" ]; then
  ok "DATABASE_URL is set"
else
  [ -f .env ] || [ -f .env.local ] && wn ".env* present — make sure DATABASE_URL is filled if tests need a DB" || true
fi

# ---- verdict ---------------------------------------------------------------
hd "Verdict"
if [ "$FAIL" = 1 ]; then
  no "BASELINE BROKEN — the repo does not build/test cleanly on this machine."
  echo "→ Fix the environment (install deps, start DB, set env) OR fix main BEFORE letting agents code."
  echo "  Otherwise the agent can't tell its own errors from pre-existing ones."
  exit 2
elif [ "$UNKNOWN" = 1 ]; then
  wn "UNDETERMINED — some scripts/tooling are missing for a full verification."
  echo "→ Agents may proceed, but must self-verify build/test the way this stack expects."
  exit 3
else
  ok "BASELINE OK — install/typecheck/lint/build/test are clean. Agents can start."
  exit 0
fi

#!/usr/bin/env bash
# ============================================================================
#  HelmForge — Interactive Setup
#  Installs the kit for a NEW (greenfield) or EXISTING project.
#  Usage:  ./setup.sh        (run from inside the extracted kit folder)
# ============================================================================
set -euo pipefail

# ---------- colors ----------
if [ -t 1 ]; then
  BOLD=$(printf '\033[1m'); DIM=$(printf '\033[2m'); RED=$(printf '\033[31m')
  GRN=$(printf '\033[32m'); YEL=$(printf '\033[33m'); BLU=$(printf '\033[36m')
  RST=$(printf '\033[0m')
else
  BOLD=""; DIM=""; RED=""; GRN=""; YEL=""; BLU=""; RST=""
fi

say()  { printf "%s\n" "$*"; }
info() { printf "%s→%s %s\n" "$BLU" "$RST" "$*"; }
ok()   { printf "%s✓%s %s\n" "$GRN" "$RST" "$*"; }
warn() { printf "%s!%s %s\n" "$YEL" "$RST" "$*"; }
err()  { printf "%s✗%s %s\n" "$RED" "$RST" "$*" >&2; }
hr()   { printf "%s────────────────────────────────────────────────────────%s\n" "$DIM" "$RST"; }

# ---------- option flags (for CLI / CI non-interactive use) ----------
# Usage: setup.sh [--target DIR] [--yes] [--name X] [--desc X] [--pm pnpm]
#                 [--fe nextjs] [--be next-api] [--mobile none] [--ai none]
#                 [--vcs github] [--profile fullstack] [--no-skills]
ASSUME_YES=0; OPT_TARGET=""; OPT_NAME=""; OPT_DESC=""; OPT_PM=""; OPT_FE=""
OPT_BE=""; OPT_MOBILE=""; OPT_AI=""; OPT_VCS=""; OPT_PROFILE=""; OPT_SKILLS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) ASSUME_YES=1;;
    --target) OPT_TARGET="${2:-}"; shift;;
    --name) OPT_NAME="${2:-}"; shift;;
    --desc) OPT_DESC="${2:-}"; shift;;
    --pm) OPT_PM="${2:-}"; shift;;
    --fe) OPT_FE="${2:-}"; shift;;
    --be) OPT_BE="${2:-}"; shift;;
    --mobile) OPT_MOBILE="${2:-}"; shift;;
    --ai) OPT_AI="${2:-}"; shift;;
    --vcs) OPT_VCS="${2:-}"; shift;;
    --profile) OPT_PROFILE="${2:-}"; shift;;
    --skills) OPT_SKILLS="yes";;
    --no-skills) OPT_SKILLS="no";;
    -h|--help)
      sed -n '2,6p' "$0" | sed 's/^#\s\?//'; exit 0;;
    *) warn "Ignoring unknown argument: $1";;
  esac
  shift
done
# any flag (besides --target) or --yes implies non-interactive
[ -n "$OPT_NAME$OPT_FE$OPT_BE$OPT_VCS$OPT_PROFILE" ] && ASSUME_YES=1

# ask "<q>" "<def>" "<KEY>"  -> echoes flag value if set, else default (non-interactive), else prompts
ask() {
  local q="$1" def="${2:-}" key="${3:-}" ans v=""
  if [ -n "$key" ]; then eval "v=\${OPT_$key:-}"; fi
  if [ -n "$v" ]; then printf "%s" "$v"; return; fi
  if [ "$ASSUME_YES" = 1 ]; then printf "%s" "$def"; return; fi
  if [ -n "$def" ]; then printf "%s%s%s [%s]: " "$BOLD" "$q" "$RST" "$def" > /dev/tty
  else printf "%s%s%s: " "$BOLD" "$q" "$RST" > /dev/tty; fi
  read -r ans < /dev/tty || true
  printf "%s" "${ans:-$def}"
}

# yesno "<q>" "Y|N" "<KEY>"  -> 0=yes 1=no; honors flags / --yes
yesno() {
  local q="$1" def="${2:-N}" key="${3:-}" ans hint v=""
  if [ -n "$key" ]; then eval "v=\${OPT_$key:-}"; fi
  if [ -n "$v" ]; then case "$v" in yes|Yes|YES|y|Y|true) return 0;; *) return 1;; esac; fi
  if [ "$ASSUME_YES" = 1 ]; then case "$def" in [Yy]*) return 0;; *) return 1;; esac; fi
  if [ "$def" = "Y" ]; then hint="[Y/n]"; else hint="[y/N]"; fi
  printf "%s%s%s %s: " "$BOLD" "$q" "$RST" "$hint" > /dev/tty
  read -r ans < /dev/tty || true
  ans="${ans:-$def}"
  case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

# sed-safe escaping for substitution values
esc() { printf '%s' "$1" | sed -e 's/[&/\]/\\&/g'; }

# ============================================================================
hr
say "${BOLD}  🏭 HelmForge — Setup${RST}"
say "${DIM}  9 agents · skills.sh · expert-voice · greenfield + feature pipelines${RST}"
hr

# ---------- locate kit ----------
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -d "$KIT_DIR/.claude/agents" ]; then
  err "Could not find .claude/agents/ next to setup.sh."
  err "Run this script from inside the extracted kit folder (helmforge/)."
  exit 1
fi
ok "Found kit at: $KIT_DIR"

# ---------- pre-flight ----------
say ""
info "Checking environment..."
MISSING=0
check_bin() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 — $("$1" --version 2>/dev/null | head -n1)"
  else
    warn "$1 not found${2:+ ($2)}"; MISSING=$((MISSING+1))
  fi
}
check_bin node "need Node 20+"
check_bin pnpm "npm i -g pnpm"
check_bin git ""
check_bin claude "npm i -g @anthropic-ai/claude-code@latest"
if [ "$MISSING" -gt 0 ]; then
  warn "$MISSING tool(s) missing. You can install later, but the pipeline needs them to run."
  yesno "Continue setup?" "Y" || { say "Stopped."; exit 0; }
fi

# ---------- target dir ----------
say ""
hr
say "${BOLD}1) Target project directory${RST}"
hr
DEFAULT_TARGET="$(pwd)"
TARGET="$(ask "Path to the repo/project" "$DEFAULT_TARGET" TARGET)"
TARGET="${TARGET/#\~/$HOME}"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
ok "Target: $TARGET"

# ---------- detect mode ----------
say ""
hr
say "${BOLD}2) Project type${RST}"
hr
HAS_PKG=0; HAS_GIT=0; HAS_SRC=0
[ -f "$TARGET/package.json" ] && HAS_PKG=1
[ -d "$TARGET/.git" ] && HAS_GIT=1
# any source files beyond config?
if find "$TARGET" -maxdepth 2 -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' \) \
   ! -path '*/node_modules/*' 2>/dev/null | head -n1 | grep -q .; then HAS_SRC=1; fi

if [ "$HAS_PKG" = 1 ] || [ "$HAS_SRC" = 1 ]; then
  GUESS="existing"
  info "Detected an EXISTING project (has package.json or source files)."
else
  GUESS="greenfield"
  info "Empty/clean directory → NEW project (greenfield)."
fi

say ""
say "  ${BOLD}1${RST}) Brand-new project (greenfield) — will use /sdlc:init to scaffold"
say "  ${BOLD}2${RST}) EXISTING project — attach the pipeline only, no scaffold"
if [ "$GUESS" = "existing" ]; then MODE_DEF="2"; else MODE_DEF="1"; fi
MODE_SEL="$(ask "Choose (1/2)" "$MODE_DEF")"
if [ "$MODE_SEL" = "1" ]; then MODE="greenfield"; else MODE="existing"; fi
ok "Mode: $MODE"

# ---------- gather inputs ----------
say ""
hr
say "${BOLD}3) Project info${RST}"
hr
BASENAME="$(basename "$TARGET")"
PROJECT_NAME="$(ask "Project name" "$BASENAME" NAME)"
PROJECT_DESC="$(ask "One-line description" "A full-stack application." DESC)"

# package prefix (slug)
SLUG_DEF="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | sed 's/^-*//;s/-*$//')"
[ -z "$SLUG_DEF" ] && SLUG_DEF="app"
PKG_SLUG="$(ask "Internal package prefix (without @)" "$SLUG_DEF")"
PKG_PREFIX="@${PKG_SLUG}"

# default branch
DEFAULT_BRANCH="main"
if [ "$HAS_GIT" = 1 ]; then
  DB_CUR="$(git -C "$TARGET" symbolic-ref --short HEAD 2>/dev/null || echo main)"
  DEFAULT_BRANCH="$DB_CUR"
fi

# package manager + stack
PKG_MANAGER="pnpm"; WRONG_PM_1="npm"; WRONG_PM_2="yarn"
STACK_KIND="next-nest"   # default
if [ "$MODE" = "existing" ] && [ "$HAS_PKG" = 1 ]; then
  info "Reading package.json to guess the stack..."
  PKGJSON="$TARGET/package.json"
  grep -q '"next"' "$PKGJSON" 2>/dev/null && HAS_NEXT=1 || HAS_NEXT=0
  grep -q '"@nestjs/core"' "$PKGJSON" 2>/dev/null && HAS_NEST=1 || HAS_NEST=0
  grep -q '"prisma"\|"@prisma/client"' "$PKGJSON" 2>/dev/null && HAS_PRISMA=1 || HAS_PRISMA=0
  [ -f "$TARGET/pnpm-lock.yaml" ] && PKG_MANAGER="pnpm"
  [ -f "$TARGET/yarn.lock" ] && { PKG_MANAGER="yarn"; WRONG_PM_1="npm"; WRONG_PM_2="pnpm"; }
  [ -f "$TARGET/package-lock.json" ] && { PKG_MANAGER="npm"; WRONG_PM_1="yarn"; WRONG_PM_2="pnpm"; }
  say "  Next.js: $([ $HAS_NEXT = 1 ] && echo yes || echo no) · NestJS: $([ $HAS_NEST = 1 ] && echo yes || echo no) · Prisma: $([ $HAS_PRISMA = 1 ] && echo yes || echo no) · PM: $PKG_MANAGER"
  if ! yesno "Is the guessed stack right? (choose N to describe it yourself)" "Y"; then
    STACK_KIND="custom"
  fi
fi

# build stack / commands / structure blocks
if [ "$STACK_KIND" = "custom" ]; then
  say ""
  warn "Enter your stack (one item per line, blank line to finish):"
  STACK_LINES=""
  while :; do
    line="$(ask "  - stack item (enter to finish)" "")"
    [ -z "$line" ] && break
    STACK_LINES="${STACK_LINES}- ${line}"$'\n'
  done
  [ -z "$STACK_LINES" ] && STACK_LINES="- (describe your stack here)"$'\n'
  STACK_BLOCK="$STACK_LINES"
  DEV_CMD="$(ask "Dev command" "$PKG_MANAGER dev")"
  TEST_CMD="$(ask "Test command" "$PKG_MANAGER test")"
  LINT_CMD="$(ask "Lint command" "$PKG_MANAGER lint")"
  COMMANDS_BLOCK="- \`${DEV_CMD}\` — start dev
- \`${TEST_CMD}\` — run tests
- \`${LINT_CMD}\` — lint
- (add your other commands here)"
  STRUCTURE_BLOCK="(describe your actual directory structure here — agents will read this CLAUDE.md)"
else
  STACK_BLOCK="- **Web**: Next.js 15 App Router, React 19, TypeScript 5.x strict, Tailwind v4, shadcn/ui
- **API**: NestJS 11, Prisma 6, Postgres 16, Redis 7 (queues/cache)
- **Tests**: Vitest + Testing Library (web), Jest + Supertest (api), Playwright 1.56+ (e2e)
- **Lint**: ESLint + Prettier (format-on-save)
- **Package manager**: ${PKG_MANAGER} (NEVER ${WRONG_PM_1}/${WRONG_PM_2})
- **Node**: 20+"
  COMMANDS_BLOCK="- \`${PKG_MANAGER} dev\` — start all apps (web :3000, api :4000)
- \`${PKG_MANAGER} test\` — all tests
- \`${PKG_MANAGER} lint\` / \`${PKG_MANAGER} typecheck\`
- \`${PKG_MANAGER} prisma migrate dev --name <desc>\` — LOCAL only (CI uses \`migrate deploy\`)
- \`${PKG_MANAGER} prisma generate\` — regenerate client"
  STRUCTURE_BLOCK="apps/
  web/          → Next.js (App Router): app/ (routing) + features/<domain>/ + components/ui/ + lib/
  api/          → NestJS: core/ + common/ + integrations/ + modules/<domain>/
packages/
  db/           → ${PKG_PREFIX}/db — Prisma schema + client (single source of truth)
  contracts/    → ${PKG_PREFIX}/contracts — Zod schemas (types + validation, both ends)
  ui/           → ${PKG_PREFIX}/ui — shared shadcn components (if web + admin)
  config/       → shared tsconfig/eslint/tailwind
docs/
  specs/<ticket>/  → product-brief, plan, requirements, acceptance.feature, ux-spec
  adr/             → Architecture Decision Records
  human-actions/   → third-party setup guides (+ README.md master checklist)
api/
  openapi.yaml  → OpenAPI 3.1 contract (BA-owned)"
fi

# ---------- agent profile ----------
say ""
hr
say "${BOLD}3b) Agent profile — does this repo have frontend, backend, or both?${RST}"
hr
# smart default from detection
PROFILE_SEL="fullstack"
if [ "${HAS_NEXT:-0}" = "1" ] && [ "${HAS_NEST:-0}" = "0" ]; then PROFILE_SEL="frontend"
elif [ "${HAS_NEST:-0}" = "1" ] && [ "${HAS_NEXT:-0}" = "0" ]; then PROFILE_SEL="backend"
fi
say "  ${BOLD}1${RST}) fullstack — all 10 agents (web + api)"
say "  ${BOLD}2${RST}) frontend  — frontend-only repo (DISABLE backend-engineer)"
say "  ${BOLD}3${RST}) backend   — backend-only repo (DISABLE ux-ui-designer + frontend-engineer)"
say "  ${BOLD}4${RST}) custom    — pick agents yourself (interactive)"
case "$PROFILE_SEL" in fullstack) PDEF=1;; frontend) PDEF=2;; backend) PDEF=3;; *) PDEF=1;; esac
info "Suggested from detected stack: ${BOLD}$PROFILE_SEL${RST}"
if [ -n "$OPT_PROFILE" ]; then
  PROFILE_SEL="$OPT_PROFILE"
else
  PSEL="$(ask "Choose (1/2/3/4)" "$PDEF")"
  case "$PSEL" in
    1) PROFILE_SEL="fullstack";; 2) PROFILE_SEL="frontend";;
    3) PROFILE_SEL="backend";; 4) PROFILE_SEL="custom";; *) PROFILE_SEL="fullstack";;
  esac
fi
ok "Profile agent: $PROFILE_SEL"

# ---------- framework selection (stack.config.yaml) ----------
say ""
hr
say "${BOLD}3c) Specific frameworks (written to stack.config.yaml)${RST}"
hr
FE_FW="nextjs"; BE_FW="nestjs"; MOB_FW="none"
if [ "$PROFILE_SEL" = "frontend" ] || [ "$PROFILE_SEL" = "fullstack" ] || [ "$PROFILE_SEL" = "custom" ]; then
  say "Frontend web framework:"
  say "  ${DIM}nextjs · nuxt · sveltekit · remix · react-router-7 · angular · astro · react-vite · none${RST}"
  FE_FW="$(ask "  frontend.framework" "nextjs" FE)"
fi
if [ "$PROFILE_SEL" = "backend" ] || [ "$PROFILE_SEL" = "fullstack" ] || [ "$PROFILE_SEL" = "custom" ]; then
  say "Backend framework:"
  say "  ${DIM}nestjs · express · fastify · hono · django · fastapi · rails · go-gin · spring-boot · laravel · none${RST}"
  BE_FW="$(ask "  backend.framework" "nestjs" BE)"
fi
MOB_FW="none"
# gate opens if user said yes OR passed a non-"none" --mobile flag
if { [ -n "$OPT_MOBILE" ] && [ "$OPT_MOBILE" != "none" ]; } || yesno "Does this repo have a mobile app?" "N"; then
  say "  ${DIM}flutter · react-native${RST}"
  MOB_FW="$(ask "  mobile.framework" "flutter" MOBILE)"
fi
AI_FW="none"
if { [ -n "$OPT_AI" ] && [ "$OPT_AI" != "none" ]; } || yesno "Does this repo have END-USER AI features (chatbot/multi-agent/RAG)?" "N"; then
  say "  ${DIM}vercel-ai-sdk (chatbot/streaming) · mastra (multi-agent/RAG/eval) · langgraph${RST}"
  AI_FW="$(ask "  ai.framework" "vercel-ai-sdk" AI)"
fi
ok "Stack: FE=$FE_FW · BE=$BE_FW · Mobile=$MOB_FW · AI=$AI_FW"

# ---------- VCS provider ----------
say ""
hr
say "${BOLD}3d) VCS provider${RST}"
hr
say "  ${DIM}github (deepest integration) · gitlab · bitbucket · azure-devops · none${RST}"
VCS_PROVIDER="$(ask "vcs.provider" "github" VCS)"
ok "VCS: $VCS_PROVIDER"

# ---------- summary before writing ----------
say ""
hr
say "${BOLD}Confirm configuration${RST}"
hr
say "  Project    : ${BOLD}${PROJECT_NAME}${RST}"
say "  Description: ${PROJECT_DESC}"
say "  Mode       : ${BOLD}${MODE}${RST}"
say "  Target     : ${TARGET}"
say "  Prefix pkg : ${BOLD}${PKG_PREFIX}/*${RST}"
say "  Branch     : ${DEFAULT_BRANCH}"
say "  PM         : ${PKG_MANAGER}"
say "  Agents     : ${BOLD}${PROFILE_SEL}${RST}"
say ""
yesno "Proceed with installation?" "Y" || { say "Cancelled."; exit 0; }

# ---------- copy files ----------
say ""
info "Copying .claude/, .github/, .helmforge/..."

backup_if_exists() {
  local p="$1"
  if [ -e "$TARGET/$p" ]; then
    local bak="$TARGET/$p.bak.$(date +%Y%m%d%H%M%S)"
    mv "$TARGET/$p" "$bak"
    warn "Backed up $p → $(basename "$bak")"
  fi
}

if [ -d "$TARGET/.claude" ]; then
  warn "$TARGET/.claude already exists."
  if yesno "Back up then overwrite .claude?" "Y"; then backup_if_exists ".claude"; else
    err "Skipping .claude copy (keeping the existing one)."; fi
fi
[ -d "$TARGET/.claude" ] || cp -R "$KIT_DIR/.claude" "$TARGET/.claude"
ok ".claude/ installed (agents + skills + commands + hooks)"

# patch settings.json to deny the WRONG package managers (keep project's PM allowed)
if [ -f "$TARGET/.claude/settings.json" ] && command -v python3 >/dev/null 2>&1; then
  SK_W1="$WRONG_PM_1" SK_W2="$WRONG_PM_2" python3 - "$TARGET/.claude/settings.json" <<'PYEOF' 2>/dev/null && ok "settings.json: deny $WRONG_PM_1/$WRONG_PM_2 (keep $PKG_MANAGER)"
import json, os, sys
p = sys.argv[1]
w1 = os.environ.get("SK_W1",""); w2 = os.environ.get("SK_W2","")
d = json.load(open(p, encoding="utf-8"))
deny = d.setdefault("permissions", {}).setdefault("deny", [])
for w in (w1, w2):
    if not w: continue
    rule = f"Bash({w} install:*)" if w == "npm" else f"Bash({w}:*)"
    if rule not in deny: deny.append(rule)
json.dump(d, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PYEOF
fi

# .github (merge-friendly: only add claude.yml if workflows dir clean of it)
mkdir -p "$TARGET/.github/workflows"
if [ -f "$KIT_DIR/.github/workflows/claude.yml" ]; then
  if [ -f "$TARGET/.github/workflows/claude.yml" ]; then
    backup_if_exists ".github/workflows/claude.yml"
  fi
  cp "$KIT_DIR/.github/workflows/claude.yml" "$TARGET/.github/workflows/claude.yml"
  ok ".github/workflows/claude.yml installed"
fi

# ---------- .helmforge/ : all kit machinery in one hidden folder ----------
mkdir -p "$TARGET/.helmforge"
cp -R "$KIT_DIR/.helmforge/." "$TARGET/.helmforge/" 2>/dev/null || true
chmod +x "$TARGET/.helmforge/configure-agents.sh" "$TARGET/.helmforge/install-skills.sh" "$TARGET/.helmforge/scripts/"*.sh 2>/dev/null || true
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
# constitution.md stays at repo root (human-facing governance doc)
[ -f "$TARGET/constitution.md" ] || cp "$KIT_DIR/constitution.md" "$TARGET/constitution.md" 2>/dev/null || true
ok ".helmforge/ (configs + scripts + configure-agents + ci-templates) + constitution.md installed"
# NB: GUIDE.md & docs/COMMANDS.md stay in the kit/repo — not copied into the user's project.

# ---------- generate CLAUDE.md ----------
say ""
info "Generating CLAUDE.md..."
WRITE_CLAUDE=1
if [ -f "$TARGET/CLAUDE.md" ]; then
  warn "$TARGET/CLAUDE.md already exists."
  say "  ${BOLD}1${RST}) Back up then overwrite  ${BOLD}2${RST}) Keep as-is, do NOT touch  ${BOLD}3${RST}) Append the SDLC section at the end"
  CHOICE="$(ask "Choose (1/2/3)" "1")"
  case "$CHOICE" in
    1) backup_if_exists "CLAUDE.md";;
    2) WRITE_CLAUDE=0; warn "Keeping the existing CLAUDE.md. You should add the SDLC conventions yourself.";;
    3) WRITE_CLAUDE=2;;
  esac
fi

if [ "$WRITE_CLAUDE" != 0 ]; then
  TEMPLATE="$KIT_DIR/CLAUDE.md.template"
  if [ ! -f "$TEMPLATE" ]; then err "Missing CLAUDE.md.template in the kit."; exit 1; fi
  TMP="$(mktemp)"
  cp "$TEMPLATE" "$TMP"

  # Pass values via env (safe for multi-line / special chars), Python reads from os.environ
  export SK_PROJECT_NAME="$PROJECT_NAME" SK_PROJECT_DESC="$PROJECT_DESC" \
         SK_PKG_PREFIX="$PKG_PREFIX" SK_DEFAULT_BRANCH="$DEFAULT_BRANCH" \
         SK_PKG_MANAGER="$PKG_MANAGER" SK_WRONG_PM_1="$WRONG_PM_1" SK_WRONG_PM_2="$WRONG_PM_2" \
         SK_STACK_BLOCK="$STACK_BLOCK" SK_COMMANDS_BLOCK="$COMMANDS_BLOCK" SK_STRUCTURE_BLOCK="$STRUCTURE_BLOCK"

  sed_fallback=0
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$TMP" <<'PYEOF'
import os, sys
p = sys.argv[1]
repl = {
 "{{PROJECT_NAME}}":        os.environ.get("SK_PROJECT_NAME", ""),
 "{{PROJECT_DESCRIPTION}}": os.environ.get("SK_PROJECT_DESC", ""),
 "{{PKG_PREFIX}}":          os.environ.get("SK_PKG_PREFIX", ""),
 "{{DEFAULT_BRANCH}}":      os.environ.get("SK_DEFAULT_BRANCH", ""),
 "{{PKG_MANAGER}}":         os.environ.get("SK_PKG_MANAGER", ""),
 "{{WRONG_PM_1}}":          os.environ.get("SK_WRONG_PM_1", ""),
 "{{WRONG_PM_2}}":          os.environ.get("SK_WRONG_PM_2", ""),
 "{{STACK_BLOCK}}":         os.environ.get("SK_STACK_BLOCK", ""),
 "{{COMMANDS_BLOCK}}":      os.environ.get("SK_COMMANDS_BLOCK", ""),
 "{{STRUCTURE_BLOCK}}":     os.environ.get("SK_STRUCTURE_BLOCK", ""),
}
s = open(p, encoding="utf-8").read()
for k, v in repl.items():
    s = s.replace(k, v)
open(p, "w", encoding="utf-8").write(s)
PYEOF
  else
    sed_fallback=1
  fi

  if [ "$sed_fallback" = "1" ]; then
    warn "python3 not available — using sed for single-line placeholders; large blocks need manual editing."
    sed -i.bak \
      -e "s/{{PROJECT_NAME}}/$(esc "$PROJECT_NAME")/g" \
      -e "s/{{PROJECT_DESCRIPTION}}/$(esc "$PROJECT_DESC")/g" \
      -e "s/{{PKG_PREFIX}}/$(esc "$PKG_PREFIX")/g" \
      -e "s/{{DEFAULT_BRANCH}}/$(esc "$DEFAULT_BRANCH")/g" \
      -e "s/{{PKG_MANAGER}}/$(esc "$PKG_MANAGER")/g" \
      -e "s/{{WRONG_PM_1}}/$(esc "$WRONG_PM_1")/g" \
      -e "s/{{WRONG_PM_2}}/$(esc "$WRONG_PM_2")/g" \
      "$TMP"
    rm -f "$TMP.bak"
    warn "Leftover {{STACK_BLOCK}}/{{COMMANDS_BLOCK}}/{{STRUCTURE_BLOCK}} — open CLAUDE.md and edit by hand."
  fi

  if [ "$WRITE_CLAUDE" = "2" ]; then
    { printf '\n\n<!-- ===== HelmForge (appended by setup.sh) ===== -->\n'; cat "$TMP"; } >> "$TARGET/CLAUDE.md"
    ok "Appended the SDLC section to the existing CLAUDE.md"
  else
    mv "$TMP" "$TARGET/CLAUDE.md"
    ok "CLAUDE.md generated from your inputs"
  fi
  rm -f "$TMP" 2>/dev/null || true
fi

# ---------- write framework choices into stack.config.yaml ----------
if [ -f "$TARGET/.helmforge/stack.config.yaml" ]; then
  # frontend.framework: first 'framework:' under 'frontend:'
  awk -v fe="$FE_FW" -v be="$BE_FW" -v mob="$MOB_FW" -v ai="$AI_FW" '
    /^frontend:/ {sec="fe"}
    /^backend:/  {sec="be"}
    /^mobile:/   {sec="mob"}
    /^ai:/       {sec="ai"}
    /^[a-z].*:/ && !/^(frontend|backend|mobile|ai):/ {sec=""}
    {
      if ($0 ~ /^  framework:/) {
        if (sec=="fe")  {print "  framework: " fe;  next}
        if (sec=="be")  {print "  framework: " be;  next}
        if (sec=="mob") {print "  framework: " mob; next}
        if (sec=="ai")  {print "  framework: " ai;  next}
      }
      print
    }
  ' "$TARGET/.helmforge/stack.config.yaml" > "$TARGET/.helmforge/stack.config.yaml.new" \
    && mv "$TARGET/.helmforge/stack.config.yaml.new" "$TARGET/.helmforge/stack.config.yaml"
  ok "stack.config.yaml updated (FE=$FE_FW BE=$BE_FW Mobile=$MOB_FW AI=$AI_FW)"
fi

# ---------- write VCS provider + branch into pipeline.config.yaml ----------
if [ -f "$TARGET/.helmforge/pipeline.config.yaml" ]; then
  sed -i.bak \
    -e "s/^  provider:.*/  provider: $VCS_PROVIDER/" \
    -e "s/^  default_branch:.*/  default_branch: $DEFAULT_BRANCH/" \
    "$TARGET/.helmforge/pipeline.config.yaml" 2>/dev/null && rm -f "$TARGET/.helmforge/pipeline.config.yaml.bak"
  ok "pipeline.config.yaml: vcs.provider=$VCS_PROVIDER, branch=$DEFAULT_BRANCH"
fi

# ---------- apply agent profile ----------
say ""
info "Applying agent profile: $PROFILE_SEL ..."
if [ -x "$TARGET/.helmforge/configure-agents.sh" ]; then
  if [ "$PROFILE_SEL" = "custom" ]; then
    ( cd "$TARGET" && .helmforge/configure-agents.sh --interactive ) || warn "configure-agents failed — rerun later."
  else
    ( cd "$TARGET" && .helmforge/configure-agents.sh --profile "$PROFILE_SEL" >/dev/null ) \
      && ok "Enabled/disabled agents per profile '$PROFILE_SEL'" \
      || warn "configure-agents failed — rerun: .helmforge/configure-agents.sh --profile $PROFILE_SEL"
  fi
else
  warn "No .helmforge/configure-agents.sh found — skipping the agent profile step."
fi

# ---------- git init for greenfield ----------
if [ "$MODE" = "greenfield" ] && [ "$HAS_GIT" = 0 ]; then
  if yesno "Initialize a git repo (git init)?" "Y"; then
    git -C "$TARGET" init -q -b "$DEFAULT_BRANCH" 2>/dev/null || git -C "$TARGET" init -q
    ok "git init xong (branch $DEFAULT_BRANCH)"
  fi
fi

# ---------- skills.sh ----------
say ""
hr
say "${BOLD}4) Install skills from skills.sh (27 skills)${RST}"
hr
if yesno "Run .helmforge/install-skills.sh now?" "N"; then
  ( cd "$TARGET" && .helmforge/install-skills.sh ) || warn "install-skills.sh failed — you can rerun later."
else
  info "Skipped. Run later with:  cd \"$TARGET\" && .helmforge/install-skills.sh"
fi

# ---------- MCP servers ----------
say ""
hr
say "${BOLD}5) Configure MCP servers${RST}"
hr
if command -v claude >/dev/null 2>&1 && yesno "Configure MCP servers now? (needs some API keys)" "N"; then
  # GitHub
  if yesno "  GitHub MCP? (needs a GitHub PAT)" "Y"; then
    GH_PAT="$(ask "    Paste GitHub PAT (blank to skip)" "")"
    if [ -n "$GH_PAT" ]; then
      ( cd "$TARGET" && claude mcp add --transport http github https://api.githubcopilot.com/mcp/ -H "Authorization: Bearer $GH_PAT" ) \
        && ok "GitHub MCP added" || warn "Adding GitHub MCP failed"
    fi
  fi
  # Context7
  if yesno "  Context7 MCP? (fresh docs, needs an API key)" "Y"; then
    C7_KEY="$(ask "    Paste Context7 API key (blank to skip)" "")"
    if [ -n "$C7_KEY" ]; then
      ( cd "$TARGET" && claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key "$C7_KEY" ) \
        && ok "Context7 MCP added" || warn "Adding Context7 failed"
    fi
  fi
  # Sequential thinking (no key)
  if yesno "  Sequential-thinking MCP? (no key needed)" "Y"; then
    ( cd "$TARGET" && claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking ) \
      && ok "sequential-thinking added" || warn "failed"
  fi
  # Playwright (no key)
  if yesno "  Playwright MCP? (cho UX + QA agents)" "Y"; then
    ( cd "$TARGET" && claude mcp add playwright -- npx @playwright/mcp@latest ) \
      && ok "playwright added" || warn "failed"
  fi
  # Postgres (needs DATABASE_URL)
  if yesno "  Postgres MCP? (needs DATABASE_URL, read-only)" "N"; then
    PG_URL="$(ask "    DATABASE_URL" "postgresql://dev:dev@localhost:5432/app")"
    ( cd "$TARGET" && claude mcp add postgres -- docker run -i --rm crystaldba/postgres-mcp-pro:latest --connection-uri "$PG_URL" --access-mode=restricted ) \
      && ok "postgres added (restricted)" || warn "failed"
  fi
  info "Verify later with:  cd \"$TARGET\" && claude  then type  /mcp"
else
  info "Skipped MCP. See the full guide in GUIDE.md (section 3, Step 5)."
fi

# ---------- GitHub Actions token ----------
say ""
hr
say "${BOLD}6) GitHub Actions (optional)${RST}"
hr
say "To let @claude be triggered from a GitHub Issue/PR:"
say "  1. ${DIM}claude setup-token${RST}  → copy sk-ant-oat01-..."
say "  2. GitHub repo → Settings → Secrets → Actions → New secret"
say "  3. Name: ${BOLD}CLAUDE_CODE_OAUTH_TOKEN${RST}  · Value: the token you just copied"
say "  4. Trong claude:  ${DIM}/install-github-app${RST}"

# ---------- preflight (existing repos) ----------
if [ "$MODE" = "existing" ] && [ -x "$TARGET/.helmforge/scripts/preflight.sh" ]; then
  say ""
  hr
  say "${BOLD}7) Preflight — verify the environment can run tests${RST}"
  hr
  if yesno "Run .helmforge/scripts/preflight.sh now to check the baseline (build/test) is clean?" "Y"; then
    ( cd "$TARGET" && .helmforge/scripts/preflight.sh ) || warn "Baseline not clean — see the log above. Fix it before letting agents code."
  else
    info "Skipped. Run later:  cd \"$TARGET\" && .helmforge/scripts/preflight.sh"
  fi
fi

# ---------- done ----------
say ""
hr
ok "${BOLD}Setup complete for: $PROJECT_NAME${RST}"
hr
say ""
say "${BOLD}Next steps:${RST}"
say "  cd \"$TARGET\""
if [ "$MODE" = "greenfield" ]; then
  say "  claude"
  say "  ${GRN}> /sdlc:init ${PROJECT_DESC}${RST}"
  say ""
  say "  ${DIM}solution-architect will choose the stack, scaffold a (feature-based) monorepo,${RST}"
  say "  ${DIM}build a walking skeleton, write ADRs + CLAUDE.md, then build the first feature.${RST}"
else
  say "  claude"
  say "  ${GRN}> /sdlc:onboard${RST}   ${DIM}# run once: analyze the repo, generate CLAUDE.md + architecture-map from real code${RST}"
  say "  ${GRN}> /sdlc <your ticket description>${RST}"
  say ""
  say "  ${DIM}/sdlc:onboard helps agents learn the existing structure + conventions before adding code (recommended for existing repos).${RST}"
  say "  ${DIM}Example: /sdlc Add a forgot-password flow, 30-min reset link, rate limit 3/hour.${RST}"
fi
say ""
say "Have not run install-skills.sh yet? →  ${DIM}.helmforge/install-skills.sh${RST}"
say "Read the full guide →  ${DIM}GUIDE.md${RST}"
say "Check MCP →  ${DIM}claude${RST} then  ${DIM}/mcp${RST}"
say ""

#!/usr/bin/env bash
# ============================================================================
#  configure-agents.sh — Enable/disable agents per agents.config.yaml
# ----------------------------------------------------------------------------
#  Usage:
#    .helmforge/configure-agents.sh                 # read agents.config.yaml and apply
#    .helmforge/configure-agents.sh --profile frontend   # set profile then apply
#    .helmforge/configure-agents.sh --interactive   # ask per agent
#    .helmforge/configure-agents.sh --status        # just show current status
#
#  Agent ACTIVE  → .claude/agents/<name>.md
#  Disabled agent → .claude/agents-disabled/<name>.md
# ============================================================================
set -euo pipefail

if [ -t 1 ]; then
  BOLD=$(printf '\033[1m'); DIM=$(printf '\033[2m'); RED=$(printf '\033[31m')
  GRN=$(printf '\033[32m'); YEL=$(printf '\033[33m'); BLU=$(printf '\033[36m'); RST=$(printf '\033[0m')
else BOLD=""; DIM=""; RED=""; GRN=""; YEL=""; BLU=""; RST=""; fi
say(){ printf "%s\n" "$*"; }
ok(){ printf "%s✓%s %s\n" "$GRN" "$RST" "$*"; }
info(){ printf "%s→%s %s\n" "$BLU" "$RST" "$*"; }
warn(){ printf "%s!%s %s\n" "$YEL" "$RST" "$*"; }
err(){ printf "%s✗%s %s\n" "$RED" "$RST" "$*" >&2; }
hr(){ printf "%s──────────────────────────────────────────────%s\n" "$DIM" "$RST"; }

HF="$(cd "$(dirname "$0")" && pwd)"          # .helmforge dir (configs + scripts live here)
ROOT="$(dirname "$HF")"                         # repo root (.claude, CLAUDE.md, constitution.md live here)
AGENTS_DIR="$ROOT/.claude/agents"
DISABLED_DIR="$ROOT/.claude/agents-disabled"
CONFIG="$HF/agents.config.yaml"

[ -d "$ROOT/.claude" ] || { err "No .claude/ found — run this from the root of a project where the kit is installed."; exit 1; }
mkdir -p "$AGENTS_DIR" "$DISABLED_DIR"

# Canonical agent list (name + emoji + role)
ALL_AGENTS="product-owner project-manager business-analyst solution-architect ux-ui-designer frontend-engineer backend-engineer mobile-engineer ai-engineer qa-engineer devops-engineer code-reviewer"
emoji_of(){ case "$1" in
  product-owner) echo "🟣";; project-manager) echo "🔵";; business-analyst) echo "🔷";;
  solution-architect) echo "🟪";; ux-ui-designer) echo "🌸";; frontend-engineer) echo "🟠";;
  backend-engineer) echo "🟢";; mobile-engineer) echo "🟦";; ai-engineer) echo "🟩";;
  qa-engineer) echo "🟡";; devops-engineer) echo "⚪";; code-reviewer) echo "🔴";; *) echo "•";; esac; }

# Read mobile.framework / ai.framework from stack.config.yaml (echo value or "none")
STACK_CONFIG="$HF/stack.config.yaml"
read_section_framework(){
  [ -f "$STACK_CONFIG" ] || { echo "none"; return; }
  awk -v sec="$1" '
    $0 ~ "^"sec":" {inm=1; next}
    inm && /^[a-z]/ {inm=0}
    inm && /framework:/ {v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); gsub(/[ \t]/,"",v); print v; exit}
  ' "$STACK_CONFIG"
}
read_mobile_framework(){ read_section_framework mobile; }
read_ai_framework(){ read_section_framework ai; }

# stack_get <section> <key>  → value or "" (reads nested key under a top-level section)
stack_get(){
  [ -f "$STACK_CONFIG" ] || { echo ""; return; }
  awk -v sec="$1" -v key="$2" '
    $0 ~ "^"sec":" {ins=1; next}
    ins && /^[a-z]/ {ins=0}
    ins && $0 ~ ("  "key":") {v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); gsub(/[ \t]/,"",v); print v; exit}
  ' "$STACK_CONFIG"
}

# does a skill exist locally or in install-skills.sh? (keeps frontmatter free of broken refs)
SKILL_LOCAL_LIST=" $(ls "$ROOT/.claude/skills" 2>/dev/null | tr '\n' ' ') "
skill_exists(){
  echo "$SKILL_LOCAL_LIST" | grep -q " $1 " && return 0
  [ -f "$HF/install-skills.sh" ] && grep -q "\"$1\"" "$HF/install-skills.sh" && return 0
  return 1
}

# compute desired skills per tier from stack.config.yaml (space-separated, may include non-existent)
compute_fe_skills(){
  local fw ui; fw="$(stack_get frontend framework)"; ui="$(stack_get frontend ui_kit)"
  local s="expert-voice design-tokens human-action-guide frontend-design web-design-guidelines"
  case "$fw" in
    nextjs)               s="$s next-best-practices vercel-react-best-practices vercel-composition-patterns prototype";;
    remix|react-router-7) s="$s vercel-react-best-practices vercel-composition-patterns prototype";;
    react-vite)           s="$s vercel-react-best-practices prototype";;
  esac
  case "$ui" in shadcn) s="$s shadcn";; esac
  echo "$s"
}
compute_be_skills(){
  local fw orm db; fw="$(stack_get backend framework)"; orm="$(stack_get backend orm)"; db="$(stack_get backend database)"
  local s="expert-voice human-action-guide openapi-3.1"
  case "$fw" in
    nestjs) s="$s nestjs-11-module";;
    next-api) s="$s next-best-practices";;   # API lives in Next.js → Next best practices apply
  esac
  case "$orm" in
    prisma) s="$s prisma-6-migration";;
    supabase-js) s="$s supabase-postgres-best-practices";;
  esac
  case "$db" in
    postgres|supabase) s="$s supabase-postgres-best-practices";;
  esac
  echo "$s"
}
compute_mobile_skills(){
  echo "expert-voice human-action-guide design-tokens"
}
compute_ai_skills(){
  echo "expert-voice ai-engineering human-action-guide openapi-3.1"
}

# rewrite the skills: block of an agent file (in agents/ or agents-disabled/) to the given list
rewrite_skills(){
  local agent="$1"; shift
  local wanted="$*"
  local file=""
  [ -f "$AGENTS_DIR/$agent.md" ] && file="$AGENTS_DIR/$agent.md"
  [ -z "$file" ] && [ -f "$DISABLED_DIR/$agent.md" ] && file="$DISABLED_DIR/$agent.md"
  [ -z "$file" ] && return 0
  # filter to existing skills, dedup preserving order
  local final="" seen=" "
  for sk in $wanted; do
    case "$seen" in *" $sk "*) continue;; esac
    if skill_exists "$sk"; then final="$final $sk"; seen="$seen$sk "; fi
  done
  # build the new block in a temp file
  local tmp; tmp="$(mktemp)"
  for sk in $final; do printf "  - %s\n" "$sk" >> "$tmp"; done
  # splice: replace lines from 'skills:' up to next top-level key
  awk -v repl="$tmp" '
    /^skills:/ {print "skills:"; system("cat " repl); ins=1; next}
    ins && /^[a-zA-Z]/ {ins=0}
    ins {next}
    {print}
  ' "$file" > "$file.new" && mv "$file.new" "$file"
  rm -f "$tmp"
  echo "$final"
}

# ---------- parse args ----------
MODE="apply"; FORCE_PROFILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) FORCE_PROFILE="${2:-}"; shift 2;;
    --profile=*) FORCE_PROFILE="${1#*=}"; shift;;
    --interactive|-i) MODE="interactive"; shift;;
    --status|-s) MODE="status"; shift;;
    --sync-skills) MODE="sync-skills"; shift;;
    --doctor|--validate) MODE="doctor"; shift;;
    -h|--help) MODE="help"; shift;;
    *) err "Unknown argument: $1"; exit 1;;
  esac
done

if [ "$MODE" = "help" ]; then
  say "${BOLD}configure-agents.sh${RST} — enable/disable agents"
  say "  .helmforge/configure-agents.sh                 read agents.config.yaml and apply"
  say "  .helmforge/configure-agents.sh --profile NAME  set profile (fullstack|frontend|backend|custom) then apply"
  say "  .helmforge/configure-agents.sh --interactive   ask per agent"
  say "  .helmforge/configure-agents.sh --status        show status"
  say "  .helmforge/configure-agents.sh --sync-skills   sync FE/BE/mobile skills to stack.config.yaml"
  say "  .helmforge/configure-agents.sh --doctor        check kit consistency"
  exit 0
fi

# ---------- sync skills to stack (shared by --sync-skills and apply) ----------
sync_skills_to_stack(){
  hr; say "${BOLD}Sync skills to stack.config.yaml${RST}"; hr
  local fe be mb r
  fe="$(stack_get frontend framework)"; be="$(stack_get backend framework)"; mb="$(read_mobile_framework)"
  r="$(rewrite_skills frontend-engineer $(compute_fe_skills))"
  [ -n "$r" ] && ok "🟠 frontend-engineer ($fe):$r"
  r="$(rewrite_skills backend-engineer $(compute_be_skills))"
  [ -n "$r" ] && ok "🟢 backend-engineer ($be):$r"
  r="$(rewrite_skills mobile-engineer $(compute_mobile_skills))"
  [ -n "$r" ] && ok "🟦 mobile-engineer ($mb):$r"
  r="$(rewrite_skills ai-engineer $(compute_ai_skills))"
  [ -n "$r" ] && ok "🟩 ai-engineer ($(read_ai_framework)):$r"
}

if [ "$MODE" = "sync-skills" ]; then
  sync_skills_to_stack
  command -v claude >/dev/null 2>&1 || true
  say ""; info "Skill frontmatter now matches the framework. Agents still pull docs via Context7 for frameworks without a dedicated skill."
  exit 0
fi

# ---------- doctor: validate kit consistency ----------
if [ "$MODE" = "doctor" ]; then
  hr; say "${BOLD}🩺 Doctor — kit check${RST}"; hr
  PROB=0
  # 1. no agent in BOTH active and disabled
  for a in $ALL_AGENTS; do
    if [ -f "$AGENTS_DIR/$a.md" ] && [ -f "$DISABLED_DIR/$a.md" ]; then
      err "$a exists in BOTH agents/ and agents-disabled/ (conflict)"; PROB=$((PROB+1))
    fi
  done
  # 2. frontmatter has name + description
  for f in "$AGENTS_DIR"/*.md "$DISABLED_DIR"/*.md; do
    [ -f "$f" ] || continue
    grep -q "^name:" "$f" || { err "$(basename "$f"): missing 'name:' frontmatter"; PROB=$((PROB+1)); }
    grep -q "^description:" "$f" || { err "$(basename "$f"): missing 'description:'"; PROB=$((PROB+1)); }
  done
  # 3. every referenced skill exists locally or in installer
  LOCAL_SKILLS="$(ls "$ROOT/.claude/skills" 2>/dev/null | tr '\n' ' ')"
  INSTALLER="$HF/install-skills.sh"
  for f in "$AGENTS_DIR"/*.md "$DISABLED_DIR"/*.md; do
    [ -f "$f" ] || continue
    skills=$(awk '/^skills:/{f=1;next} /^[a-z]/{f=0} f&&/  - /{gsub(/  - /,"");print}' "$f")
    for s in $skills; do
      if echo " $LOCAL_SKILLS " | grep -q " $s "; then continue; fi
      if [ -f "$INSTALLER" ] && grep -q "\"$s\"" "$INSTALLER"; then continue; fi
      warn "$(basename "$f"): skill '$s' is neither local nor in install-skills.sh"; PROB=$((PROB+1))
    done
  done
  # 4. hooks referenced in settings.json exist + executable
  if [ -f "$ROOT/.claude/settings.json" ]; then
    for h in block-dangerous protect-secrets; do
      hp="$ROOT/.claude/hooks/$h.sh"
      [ -f "$hp" ] || { err "missing hook: $h.sh"; PROB=$((PROB+1)); }
      [ -x "$hp" ] || { warn "hook not executable: $h.sh (chmod +x)"; PROB=$((PROB+1)); }
    done
  fi
  # 5. stack.config.yaml mobile.framework valid
  if [ -f "$STACK_CONFIG" ]; then
    mf="$(read_mobile_framework)"
    case "$mf" in flutter|react-native|none) ;; *) warn "stack.config.yaml mobile.framework='$mf' is unexpected (flutter|react-native|none)"; PROB=$((PROB+1));; esac
  fi
  # 6. pipeline.config.yaml present + vcs provider valid + preflight script exists
  if [ -f "$HF/pipeline.config.yaml" ]; then
    vp="$(awk '/^vcs:/{v=1;next} v&&/^[a-z]/{v=0} v&&/provider:/{x=$0;sub(/^[^:]*:[ \t]*/,"",x);sub(/[ \t]*#.*/,"",x);gsub(/[ \t]/,"",x);print x;exit}' "$HF/pipeline.config.yaml")"
    case "$vp" in github|gitlab|bitbucket|azure-devops|none) ;; *) warn "pipeline.config.yaml vcs.provider='$vp' is unexpected"; PROB=$((PROB+1));; esac
  else
    warn "missing pipeline.config.yaml (budget/tier/vcs/ci/preflight)"; PROB=$((PROB+1))
  fi
  [ -f "$HF/scripts/preflight.sh" ] || { warn "missing .helmforge/scripts/preflight.sh (env verification)"; PROB=$((PROB+1)); }
  [ -f "$ROOT/constitution.md" ] || warn "missing constitution.md (non-negotiable principles — run /sdlc:constitution to create)"
  # 7. living BRD: if present, validate (no dup IDs / required fields)
  if [ -f "$ROOT/docs/brd/requirements.yaml" ] && [ -x "$HF/scripts/brd.sh" ]; then
    if "$HF/scripts/brd.sh" validate >/dev/null 2>&1; then ok "living BRD valid"; else warn "docs/brd/requirements.yaml has problems (run .helmforge/scripts/brd.sh validate)"; PROB=$((PROB+1)); fi
  fi
  say ""
  if [ "$PROB" = 0 ]; then ok "No issues found. Kit is consistent."; else warn "$PROB issue(s) above."; fi
  exit 0
fi

# ---------- helpers to read config ----------
read_profile() {
  [ -f "$CONFIG" ] || { echo "fullstack"; return; }
  awk -F: '/^profile:/ {gsub(/[ \t]/,"",$2); print $2; exit}' "$CONFIG"
}
# read per-agent flag from config (echo true/false, default true)
read_flag() {
  local name="$1"
  [ -f "$CONFIG" ] || { echo "true"; return; }
  awk -v a="$name" '
    $0 ~ "^  "a":" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); gsub(/[ \t]/,"",v); print v; exit }
  ' "$CONFIG"
}

# ---------- status ----------
print_status() {
  hr; say "${BOLD}Agent status${RST}"; hr
  local n_on=0 n_off=0
  for a in $ALL_AGENTS; do
    local e; e="$(emoji_of "$a")"
    if [ -f "$AGENTS_DIR/$a.md" ]; then
      printf "  %s %s %-20s %sACTIVE%s\n" "$e" " " "$a" "$GRN" "$RST"; n_on=$((n_on+1))
    elif [ -f "$DISABLED_DIR/$a.md" ]; then
      printf "  %s %s %-20s %sOFF%s\n" "$e" " " "$a" "$DIM" "$RST"; n_off=$((n_off+1))
    else
      printf "  %s %s %-20s %sMISSING%s\n" "$e" " " "$a" "$RED" "$RST"
    fi
  done
  say ""; say "  ${GRN}$n_on active${RST} · ${DIM}$n_off off${RST}"
}

if [ "$MODE" = "status" ]; then print_status; exit 0; fi

# ---------- resolve desired set ----------
# desired_for_profile <profile> <agent> -> true/false
desired_for_profile() {
  local p="$1" a="$2"
  # mobile-engineer is driven by stack.config.yaml mobile.framework (not the web/api profile),
  # except in custom where the explicit flag wins.
  if [ "$a" = "mobile-engineer" ]; then
    if [ "$p" = "custom" ]; then read_flag "$a"; return; fi
    local mf; mf="$(read_mobile_framework)"
    if [ "$mf" = "flutter" ] || [ "$mf" = "react-native" ]; then echo "true"; else echo "false"; fi
    return
  fi
  if [ "$a" = "ai-engineer" ]; then
    if [ "$p" = "custom" ]; then read_flag "$a"; return; fi
    local af; af="$(read_ai_framework)"
    case "$af" in vercel-ai-sdk|mastra|langgraph) echo "true";; *) echo "false";; esac
    return
  fi
  case "$p" in
    fullstack) echo "true";;
    frontend)
      case "$a" in backend-engineer) echo "false";; *) echo "true";; esac;;
    backend)
      case "$a" in ux-ui-designer|frontend-engineer) echo "false";; *) echo "true";; esac;;
    custom) read_flag "$a";;
    *) echo "true";;
  esac
}

PROFILE="$(read_profile)"
if [ -n "$FORCE_PROFILE" ]; then
  PROFILE="$FORCE_PROFILE"
  # persist the chosen profile into agents.config.yaml so it sticks
  if [ -f "$CONFIG" ] && grep -q "^profile:" "$CONFIG"; then
    sed -i.bak "s/^profile:.*/profile: $PROFILE/" "$CONFIG" && rm -f "$CONFIG.bak"
    ok "agents.config.yaml → profile: $PROFILE"
  fi
fi
case "$PROFILE" in fullstack|frontend|backend|custom) ;; *)
  warn "profile '$PROFILE' invalid → using fullstack"; PROFILE="fullstack";; esac

# write agents.config.yaml as custom with explicit flags (used by interactive)
write_config_custom() {
  local pairs="$1"
  {
    echo "# Generated by configure-agents.sh --interactive"
    echo "profile: custom"
    echo "agents:"
    for kv in $pairs; do
      local name="${kv%%:*}" val="${kv##*:}"
      printf "  %-20s %s\n" "$name:" "$val"
    done
  } > "$CONFIG"
  ok "Wrote agents.config.yaml (profile: custom)"
}

# ---------- interactive ----------
if [ "$MODE" = "interactive" ]; then
  hr; say "${BOLD}Select agents (interactive)${RST}"; hr
  say "Current profile: ${BOLD}$PROFILE${RST}. Answer per agent (Enter = keep suggestion)."
  NEWFLAGS=""
  for a in $ALL_AGENTS; do
    def="$(desired_for_profile "$PROFILE" "$a")"
    hint=$([ "$def" = "true" ] && echo "[Y/n]" || echo "[y/N]")
    printf "  %s %-20s %s " "$(emoji_of "$a")" "$a" "$hint" > /dev/tty
    read -r ans < /dev/tty || true
    ans="${ans:-$([ "$def" = "true" ] && echo y || echo n)}"
    case "$ans" in [Yy]*) NEWFLAGS="$NEWFLAGS $a:true";; *) NEWFLAGS="$NEWFLAGS $a:false";; esac
  done
  # rewrite config as custom with chosen flags
  write_config_custom "$NEWFLAGS"
  PROFILE="custom"
fi

# ---------- apply: move files ----------
hr; say "${BOLD}Apply (profile: $PROFILE)${RST}"; hr
CHANGED=0
for a in $ALL_AGENTS; do
  want="$(desired_for_profile "$PROFILE" "$a")"
  active_path="$AGENTS_DIR/$a.md"
  disabled_path="$DISABLED_DIR/$a.md"
  e="$(emoji_of "$a")"

  # locate the file (could be in either place)
  if [ ! -f "$active_path" ] && [ ! -f "$disabled_path" ]; then
    warn "$e $a — .md file not found (skip)"; continue
  fi

  if [ "$want" = "true" ]; then
    if [ -f "$disabled_path" ]; then
      mv "$disabled_path" "$active_path"; ok "$e $a → ACTIVE"; CHANGED=$((CHANGED+1))
    fi
  else
    if [ -f "$active_path" ]; then
      mv "$active_path" "$disabled_path"; warn "$e $a → OFF"; CHANGED=$((CHANGED+1))
    fi
  fi
done
[ "$CHANGED" = 0 ] && info "No changes (already configured correctly)."

# ---------- update CLAUDE.md pipeline block (between markers) ----------
update_claude_md() {
  local claude="$ROOT/CLAUDE.md"
  [ -f "$claude" ] || return 0
  grep -q "<!-- ACTIVE-AGENTS:START -->" "$claude" || return 0

  local tmp; tmp="$(mktemp)"
  {
    echo "<!-- ACTIVE-AGENTS:START -->"
    echo "<!-- Auto-generated by .helmforge/configure-agents.sh — do not edit by hand between the two markers -->"
    echo "**Profile:** \`$PROFILE\`  ·  Agents ACTIVE in the pipeline:"
    echo ""
    for a in $ALL_AGENTS; do
      if [ -f "$AGENTS_DIR/$a.md" ]; then
        echo "- $(emoji_of "$a") \`$a\`"
      fi
    done
    echo ""
    echo "Disabled agents (Claude Code will NOT call them): "
    local any_off=0
    for a in $ALL_AGENTS; do
      if [ -f "$DISABLED_DIR/$a.md" ]; then echo "- $(emoji_of "$a") \`$a\` (off)"; any_off=1; fi
    done
    [ "$any_off" = 0 ] && echo "- (none)"
    echo "<!-- ACTIVE-AGENTS:END -->"
  } > "$tmp"

  # replace block
  awk -v repl="$tmp" '
    /<!-- ACTIVE-AGENTS:START -->/ {system("cat " repl); skip=1; next}
    /<!-- ACTIVE-AGENTS:END -->/ {skip=0; next}
    skip!=1 {print}
  ' "$claude" > "$claude.new" && mv "$claude.new" "$claude"
  rm -f "$tmp"
  ok "CLAUDE.md → updated the Active Agents block"
}
update_claude_md

# ---------- sync FE/BE/mobile skills to declared stack ----------
say ""
sync_skills_to_stack

# ---------- summary ----------
say ""
print_status
say ""
ACTIVE_LIST=""
for a in $ALL_AGENTS; do [ -f "$AGENTS_DIR/$a.md" ] && ACTIVE_LIST="$ACTIVE_LIST $a"; done
info "The /sdlc and /sdlc:init pipelines will only run the ACTIVE agents above."
info "FE/BE/mobile skills synced to stack.config.yaml (use --sync-skills to run separately)."
info "Reconfigure: edit agents.config.yaml / stack.config.yaml then rerun, or use --profile / --interactive."
say ""

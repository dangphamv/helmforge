#!/usr/bin/env bash
# Install all external skills.sh skills referenced by the 9 agents.
# Run this from the project root AFTER copying .claude/ from the starter kit.
#
# Skills install into .claude/skills/<skill-name>/SKILL.md
# Agents reference these skills by name in their frontmatter `skills:` field.
#
# ⚠️  SECURITY NOTE
# skills.sh skills come from third-party GitHub repos. They run in your dev
# environment. Each skill below has Socket + Snyk audit status shown.
# Review the SKILL.md after install if your project is sensitive.
# See: https://www.skills.sh/audits

set -e

# Check skills CLI is available
if ! command -v npx >/dev/null 2>&1; then
  echo "❌ npx not found. Install Node.js 20+ first." >&2
  exit 1
fi

echo "🔧 Installing skills.sh skills for SDLC pipeline agents..."
echo

# Helper
install_skill() {
  local owner_repo="$1"
  local skill_name="$2"
  local audit_status="$3"
  local for_agent="$4"
  echo "→ [$for_agent] $skill_name ($audit_status)"
  npx -y skills@latest add "https://github.com/$owner_repo" --skill "$skill_name" || {
    echo "⚠️  Failed to install $skill_name — continuing"
  }
  echo
}

# ───────── product-owner ─────────
install_skill "mattpocock/skills" "to-prd"               "Socket✓ Snyk✓" "product-owner"
install_skill "obra/superpowers"  "brainstorming"        "Socket✓ Snyk✓" "product-owner"
install_skill "coreyhaines31/marketingskills" "marketing-psychology" "Socket✓ Snyk✓" "product-owner"

# ───────── project-manager ─────────
install_skill "obra/superpowers" "writing-plans"               "Socket✓ Snyk✓" "project-manager"
install_skill "obra/superpowers" "dispatching-parallel-agents" "Socket✓ Snyk✓" "project-manager"
install_skill "obra/superpowers" "subagent-driven-development" "Socket✓ Snyk✓" "project-manager"
install_skill "mattpocock/skills" "to-issues"                  "Socket✓ Snyk✓" "project-manager"

# ───────── business-analyst ─────────
# to-prd already installed for PO above (shared)

# ───────── ux-ui-designer ─────────
install_skill "nextlevelbuilder/ui-ux-pro-max-skill" "ui-ux-pro-max"  "Socket✓ Snyk✓ ⚠️AgentTrustHub-Fail" "ux-ui-designer"
install_skill "anthropics/skills" "frontend-design"                   "Official Anthropic" "ux-ui-designer"
install_skill "vercel-labs/agent-skills" "web-design-guidelines"      "Vercel Official"    "ux-ui-designer"
install_skill "pbakaus/impeccable" "impeccable"                       "Socket✓ Snyk✓"     "ux-ui-designer"

# ───────── frontend-engineer ─────────
install_skill "vercel-labs/agent-skills" "vercel-react-best-practices" "Vercel Official" "frontend-engineer"
install_skill "vercel-labs/next-skills"  "next-best-practices"         "Vercel Official" "frontend-engineer"
install_skill "vercel-labs/agent-skills" "vercel-composition-patterns" "Vercel Official" "frontend-engineer"
install_skill "shadcn/ui" "shadcn"                                     "shadcn Official" "frontend-engineer"
install_skill "mattpocock/skills" "prototype"                          "Socket✓ Snyk✓"  "frontend-engineer"

# ───────── backend-engineer ─────────
install_skill "supabase/agent-skills" "supabase-postgres-best-practices" "Supabase Official" "backend-engineer"

# ───────── qa-engineer ─────────
install_skill "anthropics/skills" "webapp-testing"            "Official Anthropic" "qa-engineer"
install_skill "mattpocock/skills" "tdd"                       "Socket✓ Snyk✓"     "qa-engineer"
install_skill "obra/superpowers"  "systematic-debugging"      "Socket✓ Snyk✓"     "qa-engineer"

# ───────── devops-engineer ─────────
install_skill "xixu-me/skills"   "github-actions-docs"        "Socket✓ Snyk✓" "devops-engineer"
install_skill "xixu-me/skills"   "secure-linux-web-hosting"   "Socket✓ Snyk✓" "devops-engineer"
install_skill "mattpocock/skills" "handoff"                   "Socket✓ Snyk✓" "devops-engineer"

# ───────── code-reviewer ─────────
install_skill "mattpocock/skills" "grill-me"                       "Socket✓ Snyk✓" "code-reviewer"
install_skill "mattpocock/skills" "grill-with-docs"                "Socket✓ Snyk✓" "code-reviewer"
install_skill "mattpocock/skills" "diagnose"                       "Socket✓ Snyk✓" "code-reviewer"
install_skill "mattpocock/skills" "improve-codebase-architecture"  "Socket✓ Snyk✓" "code-reviewer"
install_skill "obra/superpowers"  "requesting-code-review"         "Socket✓ Snyk✓" "code-reviewer"

echo
echo "✅ Skills install complete."
echo
echo "📦 OPTIONAL — per-framework skills (install only what your repo uses):"
echo "   The kit defaults to Next.js + NestJS. If your repo uses a different framework,"
echo "   find the matching skill on https://www.skills.sh and install it. Examples:"
echo
echo "   # Vue / Nuxt:        npx skills add <repo> --skill vue-best-practices"
echo "   # Svelte/SvelteKit:  search skills.sh 'svelte'"
echo "   # Angular:           search skills.sh 'angular'"
echo "   # Astro:             search skills.sh 'astro'"
echo "   # Python/Django:     search skills.sh 'django'"
echo "   # Python/FastAPI:    search skills.sh 'fastapi'"
echo "   # Go:                search skills.sh 'golang'"
echo "   # Flutter:           search skills.sh 'flutter'"
echo "   # React Native/Expo: search skills.sh 'react-native' / 'expo'"
echo
echo "   After installing, add the skill name to 'skills:' in the relevant agent"
echo "   (.claude/agents/frontend-engineer.md | backend-engineer.md | mobile-engineer.md)."
echo "   These agents also pull framework docs via Context7, so they still work"
echo "   even without a dedicated skill."
echo
echo "Verify with: ls -la .claude/skills/"
echo "Local project-specific skills (not from skills.sh):"
echo "  - wcag-2.2-aa, owasp-top10-2025, openapi-3.1"
echo "  - nestjs-11-module, prisma-6-migration, design-tokens, playwright-agents"
echo
echo "📖 Read about each skill: https://www.skills.sh/<owner>/<repo>/<skill>"

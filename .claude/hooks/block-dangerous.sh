#!/usr/bin/env bash
# Block dangerous shell commands across all 9 agents.
# Patterns derived from real 2025-2026 incidents:
# - 12/2025 Simon Willison: rm -rf ~/
# - 2/2026 Alexey Grigorev (DataTalks.Club): terraform destroy on prod (1.94M rows lost)
# - 1/2026 James McAulay: rm -rf 11GB live on X
# Exit code 2 BLOCKS the command (per Claude Code hook contract).

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$CMD" | grep -E -q \
  '(rm[[:space:]]+-rf[[:space:]]+(/|~|\$HOME|\.\.|\.\/\.\.|\.git|\*)|terraform[[:space:]]+destroy|drop[[:space:]]+(database|table|schema)|git[[:space:]]+push[[:space:]]+.*--force.*(main|master|release)|kubectl[[:space:]]+delete[[:space:]]+(ns|namespace|all|deploy)|docker[[:space:]]+system[[:space:]]+prune[[:space:]]+-a|prisma[[:space:]]+migrate[[:space:]]+dev)'; then
  echo "🛑 BLOCKED: dangerous command pattern: $CMD" >&2
  echo "   If this is legitimate, ask the human operator to run it." >&2
  exit 2
fi

exit 0

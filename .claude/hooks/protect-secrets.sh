#!/usr/bin/env bash
# Block edits to sensitive files (env, credentials, private keys).
# Exit code 2 BLOCKS the write.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

if echo "$FILE" | grep -E -q \
  '(\.env($|\.local|\.production|\.staging)|secrets[/.]|credentials[/.]|private[_-]?key|\.pem$|\.p12$|\.pfx$|\.key$|id_rsa|id_ed25519|\.vault\.yml|kubeconfig)'; then
  echo "🛑 BLOCKED: cannot edit sensitive file: $FILE" >&2
  echo "   Secret/credential files must be managed manually (1Password, Vercel env, etc.)." >&2
  exit 2
fi

exit 0

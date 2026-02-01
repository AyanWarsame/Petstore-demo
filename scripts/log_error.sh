#!/usr/bin/env bash
set -euo pipefail

# Simple helper to append a standardized error entry to ERROR_LOG.md
# Usage:
#   ./scripts/log_error.sh "Title" "environment"            # reads body from stdin
#   ./scripts/log_error.sh "Title" "environment" "summary" # uses third arg as body

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/../ERROR_LOG.md"

timestamp="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
title="${1:-Untitled Error}"
environment="${2:-local}"
body="${3:-}"

if [ -t 0 ] && [ -z "${body}" ]; then
  echo "Provide error details via stdin or pass a third argument." >&2
  echo "Example: ./scripts/log_error.sh \"Title\" \"local\" <<'ERR'" >&2
  echo "<paste stack trace>" >&2
  echo "ERR" >&2
  exit 1
fi

if [ -z "${body}" ]; then
  body="$(cat -)"
fi

cat >> "$LOGFILE" <<EOF

---

## [$timestamp] $title

- **Environment:** $environment
- **Status:** Open
- **Steps to reproduce:**
- **Error output / Stack trace:**
\`\`\`
$body
\`\`\`
- **Root cause:**
- **Fix applied:**
- **Files changed:**
- **Notes:**
- **Resolved date:**

EOF

echo "Logged error: $title at $timestamp -> $LOGFILE"

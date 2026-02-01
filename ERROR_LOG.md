# ERROR_LOG

This file records errors encountered while working on the project and the resolutions applied.

Purpose
- Provide a single, human-readable source of truth for errors encountered during development, builds, deployments, and runtime.

How to use
- Use the helper script `scripts/log_error.sh` to append error entries quickly.
- When an error is resolved, update the corresponding entry: fill in **Root cause**, **Fix applied**, set **Status:** Resolved, and add **Resolved date**.

Template (one entry per error)

---

## [YYYY-MM-DD HH:MM:SS UTC] Error Title

- **Environment:** local / CI / prod
- **Status:** Open / Resolved
- **Steps to reproduce:**
- **Error output / Stack trace:**
```
<paste stack trace or error output here>
```
- **Root cause:**
- **Fix applied:**
- **Files changed:**
- **Notes:**
- **Resolved date:**

---

Guidelines
- Keep entries concise but include enough context to reproduce the issue.
- Link to issues, PRs, or commits in **Files changed** or **Notes** when applicable.

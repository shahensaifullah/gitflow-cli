#!/bin/bash

# ═══════════════════════════════════════════════════
#  gpush — Smart Interactive Git Tool
#  Main entry point — loads all modules from lib/
#
#  Usage:
#    gpush              → push flow
#    gpush --pull       → pull & sync
#    gpush --sync       → same as --pull
#    gpush --continue   → finish after conflict fix
#    gpush --clone      → clone a repo
#    gpush --log        → view push history
#    gpush --help       → full documentation
# ═══════════════════════════════════════════════════

# ── Find install location ─────────────────────────
GPUSH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$GPUSH_DIR/lib"

# ── Load all modules ──────────────────────────────
source "$LIB/colors.sh"
source "$LIB/help.sh"
source "$LIB/log.sh"
source "$LIB/init.sh"
source "$LIB/clone.sh"
source "$LIB/pull.sh"
source "$LIB/continue.sh"
source "$LIB/push.sh"

# ── History file ──────────────────────────────────
HISTORY_FILE="$HOME/.gpush_history"

# ── Route commands ────────────────────────────────
case "$1" in
  --help|-h)      show_help     ;;
  --log|-l)       show_log      ;;
  --clone)        clone_flow    ;;
  --pull|--sync)  pull_flow     ;;
  --continue)     continue_flow ;;
  "")             push_flow     ;;
  *)
    echo ""
    echo -e "\033[0;31m✗ Unknown command: $1\033[0m"
    echo -e "\033[2m  Run gpush --help to see all commands.\033[0m"
    echo ""
    exit 1
    ;;
esac

#!/bin/bash

# ═══════════════════════════════════════════════════
#  gpush — Smart Interactive Git Tool
#  Main entry point — loads all modules from lib/
#
#  Commands:
#    gpush                → push flow
#    gpush --pull         → pull & sync
#    gpush --sync         → same as --pull
#    gpush --checkout     → branch checkout + create
#    gpush --checkout dev → directly checkout dev
#    gpush --continue     → finish after conflict fix
#    gpush --clone        → clone a repo
#    gpush --log          → view push history
#    gpush --help         → full documentation
# ═══════════════════════════════════════════════════

# ── Load all modules from lib/ ────────────────────
# Uses the real path of this script (works with alias too)
GPUSH_DIR="$HOME/.smartgit-cli"
LIB="$GPUSH_DIR/lib"

source "$LIB/colors.sh"
source "$LIB/help.sh"
source "$LIB/log.sh"
source "$LIB/init.sh"
source "$LIB/clone.sh"
source "$LIB/pull.sh"
source "$LIB/continue.sh"
source "$LIB/push.sh"
source "$LIB/checkout.sh"

# ── History file ──────────────────────────────────
HISTORY_FILE="$HOME/.gpush_history"

# ── Route commands ────────────────────────────────
case "$1" in
  --help|-h)        show_help              ;;
  --log|-l)         show_log               ;;
  --clone)          clone_flow             ;;
  --pull|--sync)    pull_flow              ;;
  --continue)       continue_flow          ;;
  --checkout)       checkout_flow "$2"     ;;
  "")               push_flow              ;;
  *)
    echo ""
    echo -e "\033[0;31m✗ Unknown command: $1\033[0m"
    echo -e "\033[2m  Run gpush --help to see all commands.\033[0m"
    echo ""
    exit 1
    ;;
esac
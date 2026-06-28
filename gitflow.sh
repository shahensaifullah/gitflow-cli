#!/bin/bash

# ═══════════════════════════════════════════════════
#  gitflow — Smart Interactive Git Tool
#  Main entry point — loads all modules from lib/
#
#  Commands:
#    gitflow                → push flow
#    gitflow --pull         → pull & sync
#    gitflow --sync         → same as --pull
#    gitflow --checkout     → branch checkout + create
#    gitflow --checkout dev → directly checkout dev
#    gitflow --continue     → finish after conflict fix
#    gitflow --clone        → clone a repo
#    gitflow --log          → view push history
#    gitflow --help         → full documentation
# ═══════════════════════════════════════════════════

# ── Load all modules from lib/ ────────────────────
GITFLOW_DIR="$HOME/.gitflow-cli"
LIB="$GITFLOW_DIR/lib"

source "$LIB/colors.sh"
source "$LIB/help.sh"
source "$LIB/log.sh"
source "$LIB/init.sh"
source "$LIB/clone.sh"
source "$LIB/pull.sh"
source "$LIB/continue.sh"
source "$LIB/push.sh"
source "$LIB/checkout.sh"
source "$LIB/untrack.sh"
source "$LIB/delete.sh"

# ── History file ──────────────────────────────────
HISTORY_FILE="$HOME/.gitflow_history"

# ── Route commands ────────────────────────────────
case "$1" in
  --help|-h)        show_help              ;;
  --log|-l)         show_log               ;;
  --clone)          clone_flow             ;;
  --pull|--sync)    pull_flow              ;;
  --continue)       continue_flow          ;;
  --checkout)       checkout_flow "$2"     ;;
  --untrack)        untrack_flow "${@:2}"  ;;
  --delete)         delete_flow "${@:2}"   ;;
  "")               push_flow              ;;
  *)
    echo ""
    echo -e "\033[0;31m✗ Unknown command: $1\033[0m"
    echo -e "\033[2m  Run gitflow --help to see all commands.\033[0m"
    echo ""
    exit 1
    ;;
esac
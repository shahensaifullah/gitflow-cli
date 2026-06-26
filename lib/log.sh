#!/bin/bash

# ═══════════════════════════════════════════════════
#  log.sh — Push history viewer
#  Triggered by: gitflow --log or gitflow -l
#  History file: ~/.gitflow_history
# ═══════════════════════════════════════════════════

show_log() {
  echo ""
  echo -e "${BOLD}${CYAN}Push History — ~/.gitflow_history${RESET}"
  echo -e "${DIM}────────────────────────────────────────────────${RESET}"
  if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
    echo -e "${YELLOW}  No push history yet. Run gitflow to start.${RESET}"
  else
    tail -20 "$HISTORY_FILE" | tac
  fi
  echo -e "${DIM}────────────────────────────────────────────────${RESET}"
  echo -e "  ${DIM}Showing last 20 pushes. File: ~/.gitflow_history${RESET}"
  echo ""
}
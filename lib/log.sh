#!/bin/bash

# ═══════════════════════════════════════════════════
#  log.sh — Push history viewer
#  Triggered by: gpush --log or gpush -l
#  History file: ~/.gpush_history
# ═══════════════════════════════════════════════════

show_log() {
  echo ""
  echo -e "${BOLD}${CYAN}Push History — ~/.gpush_history${RESET}"
  echo -e "${DIM}────────────────────────────────────────────────${RESET}"
  if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
    echo -e "${YELLOW}  No push history yet. Run gpush to start.${RESET}"
  else
    # Show latest 20 entries, newest first
    tail -20 "$HISTORY_FILE" | tac
  fi
  echo -e "${DIM}────────────────────────────────────────────────${RESET}"
  echo -e "  ${DIM}Showing last 20 pushes. File: ~/.gpush_history${RESET}"
  echo ""
}

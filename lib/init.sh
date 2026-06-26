#!/bin/bash

# ═══════════════════════════════════════════════════
#  init.sh — Initialize a new git repo
#  Called by: push.sh when no git repo is found
#  and user picks option [1]
# ═══════════════════════════════════════════════════

init_flow() {
  echo ""
  echo -e "${BOLD}${YELLOW}── Initialize New Repo ──────────────────────────${RESET}"

  # Run git init
  git init
  echo -e "  ${GREEN}✓ Git initialized.${RESET}"

  # Set default branch to main
  git checkout -b main 2>/dev/null || git symbolic-ref HEAD refs/heads/main
  echo -e "  ${GREEN}✓ Default branch set to main.${RESET}"

  # Ask for remote URL
  echo ""
  echo -e "  ${BOLD}Paste your GitHub remote URL:${RESET}"
  echo -e "  ${DIM}SSH   : git@github.com:username/repo.git${RESET}"
  echo -e "  ${DIM}HTTPS : https://github.com/username/repo.git${RESET}"
  echo -e "  ${DIM}Press Enter to skip and add later.${RESET}"
  echo ""
  echo -n "  Remote URL: "
  read REMOTE_URL

  if [ -z "$REMOTE_URL" ]; then
    echo ""
    echo -e "  ${YELLOW}⚠ No remote URL added.${RESET}"
    echo -e "  ${DIM}Add it later with: git remote add origin <url>${RESET}"
  else
    git remote add origin "$REMOTE_URL"
    echo -e "  ${GREEN}✓ Remote origin added: $REMOTE_URL${RESET}"
  fi
  echo ""
}

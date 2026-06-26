#!/bin/bash

# ═══════════════════════════════════════════════════
#  clone.sh — Clone a GitHub repo to your laptop
#  Triggered by: gitflow --clone
#  Also called by: push.sh when no git repo is found
#  and user picks option [2]
# ═══════════════════════════════════════════════════

clone_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║           gitflow — Clone a Repo             ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "${BOLD}${YELLOW}── Clone a GitHub Repo ──────────────────────────${RESET}"
  echo -e "  ${DIM}SSH   example: git@github.com:username/repo.git${RESET}"
  echo -e "  ${DIM}HTTPS example: https://github.com/username/repo.git${RESET}"
  echo ""
  echo -n "  Paste GitHub URL: "
  read CLONE_URL

  if [ -z "$CLONE_URL" ]; then
    echo -e "  ${RED}✗ No URL provided. Aborting.${RESET}"
    exit 1
  fi

  echo ""
  echo -n "  Clone into which folder? (press Enter for current folder): "
  read CLONE_DIR

  echo ""
  if [ -z "$CLONE_DIR" ]; then
    echo -e "  ${CYAN}Cloning...${RESET}"
    git clone "$CLONE_URL"
  else
    echo -e "  ${CYAN}Cloning into $CLONE_DIR...${RESET}"
    git clone "$CLONE_URL" "$CLONE_DIR"
  fi

  if [ $? -eq 0 ]; then
    REPO_NAME=$(basename "$CLONE_URL" .git)
    DEST="${CLONE_DIR:-$REPO_NAME}"
    echo ""
    echo -e "  ${GREEN}✓ Clone successful!${RESET}"
    echo ""
    echo -e "  ${BOLD}Next step — go into your project:${RESET}"
    echo -e "  ${CYAN}  cd $DEST${RESET}"
    echo ""
    echo -e "  ${DIM}Then run gitflow to start pushing code.${RESET}"
    echo ""
  else
    echo ""
    echo -e "  ${RED}✗ Clone failed.${RESET}"
    echo -e "  ${DIM}Possible reasons:${RESET}"
    echo -e "  ${DIM}• Wrong URL — double check on GitHub${RESET}"
    echo -e "  ${DIM}• SSH key not set up — try HTTPS URL instead${RESET}"
    echo -e "  ${DIM}• No internet connection${RESET}"
    exit 1
  fi
}
#!/bin/bash

# ═══════════════════════════════════════════════════
#  install.sh — Installer for gitflow-cli
#
#  How to use:
#  1. Clone or download this repo
#  2. cd into the repo folder
#  3. Run: bash install.sh
# ═══════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Install location ──────────────────────────────
INSTALL_DIR="$HOME/.gitflow-cli"
LIB_DIR="$INSTALL_DIR/lib"

# ── Where this script is running from ────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║         gitflow-cli — Installer              ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""

# ── Step 1: Create folder structure ──────────────
echo -e "  ${CYAN}[1/4] Creating folders...${RESET}"
mkdir -p "$LIB_DIR"
echo -e "  ${GREEN}✓ $INSTALL_DIR/${RESET}"
echo -e "  ${GREEN}✓ $LIB_DIR/${RESET}"

# ── Step 2: Copy files ────────────────────────────
echo ""
echo -e "  ${CYAN}[2/4] Copying files...${RESET}"

# Find main executable (gitflow.sh or gpush.sh)
MAIN_FILE=""
if [ -f "$REPO_DIR/gitflow.sh" ]; then
  MAIN_FILE="$REPO_DIR/gitflow.sh"
elif [ -f "$REPO_DIR/gpush.sh" ]; then
  MAIN_FILE="$REPO_DIR/gpush.sh"
else
  echo -e "  ${RED}✗ Main script not found in $REPO_DIR${RESET}"
  echo -e "  ${DIM}Files found:${RESET}"
  ls "$REPO_DIR" | while read f; do echo -e "  ${DIM}  $f${RESET}"; done
  echo ""
  echo -e "  ${DIM}Make sure you run: bash install.sh from inside the repo folder.${RESET}"
  exit 1
fi

# Copy main executable
cp "$MAIN_FILE" "$INSTALL_DIR/gitflow.sh"
echo -e "  ${GREEN}✓ gitflow.sh${RESET}"

# Copy lib folder directly
if [ -d "$REPO_DIR/lib" ]; then
  cp -r "$REPO_DIR/lib/"* "$LIB_DIR/"
  echo -e "  ${GREEN}✓ lib/ folder copied${RESET}"
  for f in "$LIB_DIR/"*.sh; do
    echo -e "  ${GREEN}✓ lib/$(basename $f)${RESET}"
  done
else
  echo -e "  ${RED}✗ lib/ folder not found in $REPO_DIR${RESET}"
  echo -e "  ${DIM}Make sure your repo has a lib/ folder with all the sh files.${RESET}"
  exit 1
fi

# ── Step 3: Make all files executable ────────────
echo ""
echo -e "  ${CYAN}[3/4] Setting permissions...${RESET}"
chmod +x "$INSTALL_DIR/gitflow.sh"
chmod +x "$LIB_DIR/"*.sh 2>/dev/null
echo -e "  ${GREEN}✓ chmod +x set on gitflow.sh${RESET}"
echo -e "  ${GREEN}✓ chmod +x set on all lib files${RESET}"

# ── Step 4: Add alias to shell config ────────────
echo ""
echo -e "  ${CYAN}[4/4] Adding to terminal...${RESET}"

# Detect shell config file
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
  SHELL_NAME="zsh"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
  SHELL_NAME="bash"
elif [ -f "$HOME/.bash_profile" ]; then
  SHELL_RC="$HOME/.bash_profile"
  SHELL_NAME="bash"
else
  SHELL_RC="$HOME/.zshrc"
  SHELL_NAME="zsh"
fi

# Add alias only if not already there
if grep -q 'gitflow-cli' "$SHELL_RC" 2>/dev/null; then
  echo -e "  ${YELLOW}⚠ Already configured in $SHELL_RC — skipping.${RESET}"
else
  echo ""                                                              >> "$SHELL_RC"
  echo "# gitflow-cli — smart interactive git tool"                   >> "$SHELL_RC"
  echo "alias gitflow=\"\$HOME/.gitflow-cli/gitflow.sh\""             >> "$SHELL_RC"
  echo -e "  ${GREEN}✓ Alias added to $SHELL_RC ($SHELL_NAME)${RESET}"
  echo -e "  ${GREEN}✓ alias gitflow → ~/.gitflow-cli/gitflow.sh${RESET}"
fi

# ── Done ──────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║  ✓ gitflow-cli installed successfully!       ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Installed at:${RESET}"
echo -e "  ${DIM}  ~/.gitflow-cli/${RESET}"
echo -e "  ${DIM}  ~/.gitflow-cli/lib/${RESET}"
echo ""
echo -e "  ${BOLD}Reload your terminal:${RESET}"
echo -e "  ${CYAN}  source $SHELL_RC${RESET}"
echo ""
echo -e "  ${BOLD}Then start using:${RESET}"
echo -e "  ${CYAN}  gitflow${RESET}              ${DIM}→ push your code${RESET}"
echo -e "  ${CYAN}  gitflow --pull${RESET}       ${DIM}→ pull latest${RESET}"
echo -e "  ${CYAN}  gitflow --checkout${RESET}   ${DIM}→ switch or create branch${RESET}"
echo -e "  ${CYAN}  gitflow --clone${RESET}      ${DIM}→ clone a repo${RESET}"
echo -e "  ${CYAN}  gitflow --help${RESET}       ${DIM}→ all commands${RESET}"
echo ""
echo -e "  ${DIM}To uninstall:${RESET}"
echo -e "  ${DIM}  rm -rf ~/.gitflow-cli${RESET}"
echo -e "  ${DIM}  Then remove the gitflow alias from $SHELL_RC${RESET}"
echo ""
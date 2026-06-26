#!/bin/bash

# ═══════════════════════════════════════════════════
#  install.sh — Installer for smartgit-cli
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
# Hidden folder under home: ~/.smartgit-cli/
INSTALL_DIR="$HOME/.smartgit-cli"
LIB_DIR="$INSTALL_DIR/lib"

# ── Where this script is running from ────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║        smartgit-cli — Installer              ║${RESET}"
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

# Check gpush.sh exists
if [ ! -f "$REPO_DIR/gpush.sh" ]; then
  echo -e "  ${RED}✗ gpush.sh not found in $REPO_DIR${RESET}"
  echo -e "  ${DIM}Make sure you run: bash install.sh from inside the repo folder.${RESET}"
  exit 1
fi

# Copy main executable
cp "$REPO_DIR/gpush.sh" "$INSTALL_DIR/gpush.sh"
echo -e "  ${GREEN}✓ gpush.sh${RESET}"

# Copy lib files — look in lib/ subfolder first, then root
copy_lib_file() {
  local filename=$1
  if [ -f "$REPO_DIR/lib/$filename" ]; then
    cp "$REPO_DIR/lib/$filename" "$LIB_DIR/$filename"
    echo -e "  ${GREEN}✓ lib/$filename${RESET}"
  elif [ -f "$REPO_DIR/$filename" ]; then
    cp "$REPO_DIR/$filename" "$LIB_DIR/$filename"
    echo -e "  ${GREEN}✓ lib/$filename${RESET} ${DIM}(copied from root)${RESET}"
  else
    echo -e "  ${RED}✗ $filename not found — skipping${RESET}"
  fi
}

copy_lib_file colors.sh
copy_lib_file help.sh
copy_lib_file log.sh
copy_lib_file init.sh
copy_lib_file clone.sh
copy_lib_file pull.sh
copy_lib_file continue.sh
copy_lib_file push.sh
copy_lib_file checkout.sh

# ── Step 3: Make all files executable ────────────
echo ""
echo -e "  ${CYAN}[3/4] Setting permissions...${RESET}"
chmod +x "$INSTALL_DIR/gpush.sh"
chmod +x "$LIB_DIR/"*.sh 2>/dev/null
echo -e "  ${GREEN}✓ chmod +x set on gpush.sh${RESET}"
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
if grep -q 'smartgit-cli' "$SHELL_RC" 2>/dev/null; then
  echo -e "  ${YELLOW}⚠ Already configured in $SHELL_RC — skipping.${RESET}"
else
  echo ""                                                             >> "$SHELL_RC"
  echo "# smartgit-cli — smart interactive git tool"                 >> "$SHELL_RC"
  echo "alias gpush=\"\$HOME/.smartgit-cli/gpush.sh\""               >> "$SHELL_RC"
  echo -e "  ${GREEN}✓ Alias added to $SHELL_RC ($SHELL_NAME)${RESET}"
fi

# ── Done ──────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║  ✓ smartgit-cli installed successfully!      ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Installed at:${RESET}"
echo -e "  ${DIM}  ~/.smartgit-cli/${RESET}"
echo -e "  ${DIM}  ~/.smartgit-cli/lib/${RESET}"
echo ""
echo -e "  ${BOLD}Reload your terminal:${RESET}"
echo -e "  ${CYAN}  source $SHELL_RC${RESET}"
echo ""
echo -e "  ${BOLD}Then start using:${RESET}"
echo -e "  ${CYAN}  gpush${RESET}              ${DIM}→ push your code${RESET}"
echo -e "  ${CYAN}  gpush --pull${RESET}       ${DIM}→ pull latest${RESET}"
echo -e "  ${CYAN}  gpush --checkout${RESET}   ${DIM}→ switch or create branch${RESET}"
echo -e "  ${CYAN}  gpush --clone${RESET}      ${DIM}→ clone a repo${RESET}"
echo -e "  ${CYAN}  gpush --help${RESET}       ${DIM}→ all commands${RESET}"
echo ""
echo -e "  ${DIM}To uninstall:${RESET}"
echo -e "  ${DIM}  rm -rf ~/.smartgit-cli${RESET}"
echo -e "  ${DIM}  Then remove the gpush alias from $SHELL_RC${RESET}"
echo ""
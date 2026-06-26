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
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Where to install ──────────────────────────────
INSTALL_DIR="$HOME/smartgit-cli"
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

# Verify source files exist before copying
if [ ! -f "$REPO_DIR/gpush.sh" ]; then
  echo -e "  ${RED}✗ gpush.sh not found in $REPO_DIR${RESET}"
  echo -e "  ${DIM}Make sure you run this from inside the smartgit-cli repo folder.${RESET}"
  exit 1
fi

if [ ! -d "$REPO_DIR/lib" ]; then
  echo -e "  ${YELLOW}⚠ lib/ folder not found. Creating it...${RESET}"
  mkdir -p "$REPO_DIR/lib"
fi

# Copy main executable
cp "$REPO_DIR/gpush.sh" "$INSTALL_DIR/gpush.sh"
echo -e "  ${GREEN}✓ gpush.sh${RESET}"

# Copy each lib file explicitly
# If lib files are in REPO_DIR/lib/ use that, otherwise check REPO_DIR root
find_lib_file() {
  local filename=$1
  if [ -f "$REPO_DIR/lib/$filename" ]; then
    echo "$REPO_DIR/lib/$filename"
  elif [ -f "$REPO_DIR/$filename" ]; then
    echo "$REPO_DIR/$filename"
  else
    echo ""
  fi
}

for FILE in colors.sh help.sh log.sh init.sh clone.sh pull.sh continue.sh push.sh; do
  SRC=$(find_lib_file "$FILE")
  if [ -n "$SRC" ]; then
    cp "$SRC" "$LIB_DIR/$FILE" && echo -e "  ${GREEN}✓ lib/$FILE${RESET}"
  else
    echo -e "  ${RED}✗ $FILE not found — skipping${RESET}"
  fi
done

# ── Step 3: Make gpush executable ────────────────
echo ""
echo -e "  ${CYAN}[3/4] Setting permissions...${RESET}"
chmod +x "$INSTALL_DIR/gpush.sh"
chmod +x "$LIB_DIR/"*.sh
echo -e "  ${GREEN}✓ chmod +x set on gpush.sh and all lib files${RESET}"

# ── Step 4: Export to shell ───────────────────────
echo ""
echo -e "  ${CYAN}[4/4] Adding to shell...${RESET}"

# Detect shell config
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

# Only add if not already there
if grep -q 'smartgit-cli' "$SHELL_RC" 2>/dev/null; then
  echo -e "  ${GREEN}✓ Already configured in $SHELL_RC${RESET}"
else
  echo ""                                                        >> "$SHELL_RC"
  echo "# smartgit-cli — smart interactive git tool"            >> "$SHELL_RC"
  echo "export PATH=\"\$HOME/smartgit-cli:\$PATH\""             >> "$SHELL_RC"
  echo "alias gpush=\"\$HOME/smartgit-cli/gpush.sh\""           >> "$SHELL_RC"
  echo -e "  ${GREEN}✓ PATH exported in $SHELL_RC ($SHELL_NAME)${RESET}"
  echo -e "  ${GREEN}✓ Alias added: gpush${RESET}"
fi

# ── Done ──────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║  ✓ smartgit-cli installed successfully!      ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Installed at:${RESET} ${DIM}~/smartgit-cli/${RESET}"
echo ""
echo -e "  ${BOLD}Reload your terminal:${RESET}"
echo -e "  ${CYAN}  source $SHELL_RC${RESET}"
echo ""
echo -e "  ${BOLD}Then use:${RESET}"
echo -e "  ${CYAN}  gpush${RESET}            ${DIM}→ push your code${RESET}"
echo -e "  ${CYAN}  gpush --pull${RESET}     ${DIM}→ pull latest${RESET}"
echo -e "  ${CYAN}  gpush --clone${RESET}    ${DIM}→ clone a repo${RESET}"
echo -e "  ${CYAN}  gpush --help${RESET}     ${DIM}→ all commands${RESET}"
echo ""
echo -e "  ${DIM}To uninstall: rm -rf ~/smartgit-cli${RESET}"
echo -e "  ${DIM}Then remove the smartgit-cli lines from $SHELL_RC${RESET}"
echo ""
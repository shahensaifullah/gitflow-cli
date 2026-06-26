#!/bin/bash

# ═══════════════════════════════════════════════════
#  continue.sh — Finish push after manual conflict fix
#  Triggered by: gpush --continue
#
#  Flow:
#  1. Check no remaining conflict markers
#  2. Stage all resolved files
#  3. Ask for commit message
#  4. Push to current branch
# ═══════════════════════════════════════════════════

continue_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║         gpush — Continue After Fix           ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "  ${RED}✗ Not a git repository.${RESET}"
    exit 1
  fi

  # Check if any conflicts still remain
  CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)

  if [ -n "$CONFLICT_FILES" ]; then
    echo -e "  ${RED}⚠  Still has unresolved conflicts:${RESET}"
    echo "$CONFLICT_FILES" | while read -r file; do
      echo -e "    ${RED}→ $file${RESET}"
    done
    echo ""
    echo -e "  ${YELLOW}Open each file and remove all conflict markers:${RESET}"
    echo -e "  ${DIM}<<<<<<< HEAD${RESET}"
    echo -e "  ${DIM}=======${RESET}"
    echo -e "  ${DIM}>>>>>>>${RESET}"
    echo ""
    echo -e "  ${YELLOW}Save the files, then run: ${GREEN}gpush --continue${RESET}${YELLOW} again.${RESET}"
    exit 1
  fi

  # Stage resolved files
  echo -e "  ${CYAN}Staging resolved files...${RESET}"
  git add .
  echo -e "  ${GREEN}✓ All files staged.${RESET}"

  # Ask for commit message
  echo ""
  echo -n "  Commit message (press Enter for 'merge: resolved conflicts'): "
  read FIX_MSG

  if [ -z "$FIX_MSG" ]; then
    FIX_MSG="merge: resolved conflicts"
  fi

  git commit -m "$FIX_MSG" > /dev/null 2>&1
  echo -e "  ${GREEN}✓ Committed: \"$FIX_MSG\"${RESET}"

  # Push
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo ""
  echo -e "  ${CYAN}Pushing to origin/$CURRENT_BRANCH...${RESET}"
  git push origin "$CURRENT_BRANCH"

  if [ $? -eq 0 ]; then
    echo ""
    echo -e "  ${GREEN}✓ Done! Conflicts resolved and pushed to origin/$CURRENT_BRANCH${RESET}"
    echo ""
  else
    echo -e "  ${RED}✗ Push failed.${RESET}"
    echo -e "  ${DIM}Check your internet connection or run: gpush --pull${RESET}"
    exit 1
  fi
}

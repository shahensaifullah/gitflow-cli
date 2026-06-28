#!/bin/bash

# ═══════════════════════════════════════════════════
#  untrack.sh — Remove files/folders from git tracking
#  Triggered by: gitflow --untrack <path> [path...] [--push]
# ═══════════════════════════════════════════════════

untrack_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║           gitflow — Untrack                  ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "  ${RED}✗ No git repository found in this folder.${RESET}"
    echo ""
    return 1
  fi

  local PATHS=()
  local AUTO_PUSH=false

  for arg in "$@"; do
    if [ "$arg" == "--push" ]; then
      AUTO_PUSH=true
    else
      PATHS+=("$arg")
    fi
  done

  if [[ ${#PATHS[@]} -eq 0 ]]; then
    echo -e "  ${RED}✗ No path specified.${RESET}"
    echo -e "  ${DIM}Usage: gitflow --untrack <path> [path...] [--push]${RESET}"
    echo ""
    return 1
  fi

  local processed=0
  local processed_names=()

  for item in "${PATHS[@]}"; do
    local CLEAN="${item%/}"
    CLEAN="${CLEAN#/}"

    echo -e "  ${BOLD}${YELLOW}── Processing: $CLEAN ────────────────────────────${RESET}"

    if [ -f "$CLEAN" ]; then
      # ── File ──
      echo -e "  ${DIM}Detected: file${RESET}"

      local is_tracked=false
      if git ls-files --error-unmatch "$CLEAN" > /dev/null 2>&1; then
        is_tracked=true
      fi

      if [ "$is_tracked" == true ]; then
        git rm --cached "$CLEAN" > /dev/null 2>&1
        echo -e "  ${GREEN}✓${RESET} Removed '$CLEAN' from git tracking"
        echo -e "    ${DIM}File kept on your computer.${RESET}"
      else
        echo -e "  ${YELLOW}⚠${RESET} '$CLEAN' is not tracked by git"
      fi

      if [[ -f .gitignore ]] && grep -qxF "$CLEAN" .gitignore; then
        echo -e "  ${DIM}  .gitignore already has $CLEAN${RESET}"
      else
        echo "$CLEAN" >> .gitignore
        echo -e "  ${GREEN}✓${RESET} Added '$CLEAN' to .gitignore"
      fi

      git add .gitignore > /dev/null 2>&1
      processed=$((processed + 1))
      processed_names+=("$CLEAN")

    elif [ -d "$CLEAN" ]; then
      # ── Folder ──
      echo -e "  ${DIM}Detected: folder${RESET}"

      local is_tracked=false
      if git ls-files --error-unmatch "$CLEAN" > /dev/null 2>&1; then
        is_tracked=true
      fi

      if [ "$is_tracked" == true ]; then
        git rm -r --cached "$CLEAN/" > /dev/null 2>&1
        echo -e "  ${GREEN}✓${RESET} Removed '$CLEAN/' contents from git tracking"
        echo -e "    ${DIM}Files kept on your computer.${RESET}"
      else
        echo -e "  ${YELLOW}⚠${RESET} '$CLEAN' is not tracked by git"
      fi

      local gitignore_entry="$CLEAN/*"
      local gitkeep_entry="!$CLEAN/.gitkeep"

      if [[ -f .gitignore ]] && grep -qxF "$gitignore_entry" .gitignore; then
        echo -e "  ${DIM}  .gitignore already has $gitignore_entry${RESET}"
      else
        echo "$gitignore_entry" >> .gitignore
        echo -e "  ${GREEN}✓${RESET} Added '$gitignore_entry' to .gitignore"
      fi

      if [[ -f .gitignore ]] && grep -qxF "$gitkeep_entry" .gitignore; then
        echo -e "  ${DIM}  .gitignore already has $gitkeep_entry${RESET}"
      else
        echo "$gitkeep_entry" >> .gitignore
        echo -e "  ${GREEN}✓${RESET} Added '$gitkeep_entry' to .gitignore"
      fi

      if [[ ! -f "$CLEAN/.gitkeep" ]]; then
        touch "$CLEAN/.gitkeep"
        echo -e "  ${GREEN}✓${RESET} Created '$CLEAN/.gitkeep'"
        echo -e "    ${DIM}Folder structure preserved on GitHub.${RESET}"
      else
        echo -e "  ${DIM}  $CLEAN/.gitkeep already exists${RESET}"
      fi

      git add .gitignore "$CLEAN/.gitkeep" > /dev/null 2>&1
      processed=$((processed + 1))
      processed_names+=("$CLEAN/")

    else
      echo -e "  ${RED}✗ '$CLEAN' does not exist. Skipping.${RESET}"
    fi

    echo ""
  done

  if [[ $processed -eq 0 ]]; then
    echo -e "  ${YELLOW}⚠ Nothing to commit.${RESET}"
    echo ""
    return 0
  fi

  # ── Summary ──
  echo -e "  ${BOLD}${YELLOW}── Summary ──────────────────────────────────────${RESET}"
  for name in "${processed_names[@]}"; do
    echo -e "  ${GREEN}✓${RESET} $name"
  done
  echo ""

  # ── Commit ──
  echo -e "  ${BOLD}${YELLOW}── Commit ───────────────────────────────────────${RESET}"
  local path_list
  path_list=$(printf "%s " "${processed_names[@]}")
  path_list="${path_list% }"
  local suggested_msg="chore: untrack $path_list, preserve structure"

  echo -e "  ${DIM}Suggested: \"$suggested_msg\"${RESET}"
  echo -e "  ${DIM}Press Enter to accept, or type your own.${RESET}"
  echo -n "  Commit message: "
  read CUSTOM_MSG

  local commit_msg="${CUSTOM_MSG:-$suggested_msg}"
  git commit -m "$commit_msg" > /dev/null 2>&1
  echo -e "  ${GREEN}✓${RESET} Committed"

  # ── Push ──
  local branch
  branch=$(git branch --show-current)

  if [ "$AUTO_PUSH" == true ]; then
    git push origin "$branch" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
      echo -e "  ${GREEN}✓${RESET} Pushed to ${CYAN}origin/$branch${RESET}"
    else
      echo -e "  ${RED}✗ Push failed.${RESET}"
    fi
  else
    echo -n "  Push to origin/$branch? (y/n): "
    read PUSH_CHOICE
    if [[ "$PUSH_CHOICE" == "y" || "$PUSH_CHOICE" == "Y" ]]; then
      git push origin "$branch" > /dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✓${RESET} Pushed to ${CYAN}origin/$branch${RESET}"
      else
        echo -e "  ${RED}✗ Push failed.${RESET}"
      fi
    fi
  fi

  echo ""
}

#!/bin/bash

# ═══════════════════════════════════════════════════
#  delete.sh — Permanently remove files/folders
#  Triggered by: gitflow --delete <path> [path...] [--push]
# ═══════════════════════════════════════════════════

delete_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║           gitflow — Delete                   ║${RESET}"
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
    echo -e "  ${DIM}Usage: gitflow --delete <path> [path...] [--push]${RESET}"
    echo ""
    return 1
  fi

  # ── Clean paths ──
  local CLEAN_PATHS=()
  local VALID_PATHS=()
  for item in "${PATHS[@]}"; do
    local CLEAN="${item%/}"
    CLEAN="${CLEAN#/}"
    CLEAN_PATHS+=("$CLEAN")
    if [ -f "$CLEAN" ] || [ -d "$CLEAN" ]; then
      VALID_PATHS+=("$CLEAN")
    else
      echo -e "  ${RED}✗ '$CLEAN' does not exist. Skipping.${RESET}"
    fi
  done

  if [[ ${#VALID_PATHS[@]} -eq 0 ]]; then
    echo -e "  ${YELLOW}⚠ Nothing to delete.${RESET}"
    echo ""
    return 0
  fi

  # ── Confirmation ──
  echo -e "  ${BOLD}${YELLOW}── Confirm Deletion ──────────────────────────────${RESET}"
  echo ""
  echo -e "  The following will be ${RED}permanently deleted${RESET}:"
  for p in "${VALID_PATHS[@]}"; do
    if [ -d "$p" ]; then
      echo -e "  ${RED}•${RESET} $p/"
    else
      echo -e "  ${RED}•${RESET} $p"
    fi
  done
  echo ""
  echo -e "  This removes them from GitHub ${RED}AND${RESET} your computer."
  echo -e "  ${YELLOW}⚠ This cannot be undone.${RESET}"
  echo ""
  echo -n "  Type 'yes' to confirm: "
  read CONFIRM

  if [ "$CONFIRM" != "yes" ]; then
    echo ""
    echo -e "  ${YELLOW}⚠ Aborted. Nothing was deleted.${RESET}"
    echo ""
    return 0
  fi

  echo ""

  local processed=0
  local processed_names=()
  local folder_choices=()

  for CLEAN in "${VALID_PATHS[@]}"; do
    echo -e "  ${BOLD}${YELLOW}── Processing: $CLEAN ────────────────────────────${RESET}"

    if [ -f "$CLEAN" ]; then
      # ── File ──
      echo -e "  ${DIM}Detected: file${RESET}"

      local is_tracked=false
      if git ls-files --error-unmatch "$CLEAN" > /dev/null 2>&1; then
        is_tracked=true
      fi

      if [ "$is_tracked" == true ]; then
        git rm -f "$CLEAN" > /dev/null 2>&1
        echo -e "  ${GREEN}✓${RESET} Deleted from git tracking"
        echo -e "  ${GREEN}✓${RESET} Deleted from local computer"
      else
        echo -e "  ${YELLOW}⚠${RESET} '$CLEAN' is not tracked by git"
        rm -f "$CLEAN"
        echo -e "  ${GREEN}✓${RESET} Deleted from local computer"
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
      echo ""
      echo -e "  What do you want to delete?"
      echo -e "  ${CYAN}[1]${RESET} Whole folder"
      echo -e "      ${DIM}→ Deletes $CLEAN/ completely.${RESET}"
      echo -e "      ${DIM}  Removes from GitHub and your computer.${RESET}"
      echo -e "  ${CYAN}[2]${RESET} Contents only"
      echo -e "      ${DIM}→ Deletes all files inside $CLEAN/.${RESET}"
      echo -e "      ${DIM}  Keeps the empty folder with .gitkeep on GitHub.${RESET}"
      echo ""
      echo -n "  Your choice: "
      read FOLDER_CHOICE

      if [[ "$FOLDER_CHOICE" == "1" ]]; then
        # ── Whole folder ──
        local is_tracked=false
        if git ls-files --error-unmatch "$CLEAN" > /dev/null 2>&1; then
          is_tracked=true
        fi

        if [ "$is_tracked" == true ]; then
          git rm -rf "$CLEAN" > /dev/null 2>&1
        fi
        rm -rf "$CLEAN"
        echo -e "  ${GREEN}✓${RESET} Deleted '$CLEAN/' completely"

        local gitignore_entry="$CLEAN/"
        if [[ -f .gitignore ]] && grep -qxF "$gitignore_entry" .gitignore; then
          echo -e "  ${DIM}  .gitignore already has $gitignore_entry${RESET}"
        else
          echo "$gitignore_entry" >> .gitignore
          echo -e "  ${GREEN}✓${RESET} Added '$gitignore_entry' to .gitignore"
        fi

        git add .gitignore > /dev/null 2>&1
        processed=$((processed + 1))
        processed_names+=("$CLEAN/")

      elif [[ "$FOLDER_CHOICE" == "2" ]]; then
        # ── Contents only ──
        local is_tracked=false
        if git ls-files --error-unmatch "$CLEAN" > /dev/null 2>&1; then
          is_tracked=true
        fi

        if [ "$is_tracked" == true ]; then
          git rm -r --cached "$CLEAN/" > /dev/null 2>&1
          echo -e "  ${GREEN}✓${RESET} Deleted all contents of '$CLEAN/' from git tracking"
        else
          echo -e "  ${YELLOW}⚠${RESET} '$CLEAN' is not tracked by git"
        fi

        find "$CLEAN" -mindepth 1 -not -name '.gitkeep' -delete 2>/dev/null
        echo -e "  ${GREEN}✓${RESET} Deleted all files inside '$CLEAN/' locally"
        echo -e "  ${GREEN}✓${RESET} Kept '$CLEAN/' folder"

        touch "$CLEAN/.gitkeep"
        echo -e "  ${GREEN}✓${RESET} Created '$CLEAN/.gitkeep'"

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

        git add .gitignore "$CLEAN/.gitkeep" > /dev/null 2>&1
        processed=$((processed + 1))
        processed_names+=("$CLEAN/")

      else
        echo -e "  ${YELLOW}⚠ Invalid choice. Skipping '$CLEAN'.${RESET}"
      fi
    fi

    echo ""
  done

  if [[ $processed -eq 0 ]]; then
    echo -e "  ${YELLOW}⚠ Nothing to commit.${RESET}"
    echo ""
    return 0
  fi

  # ── Commit ──
  echo -e "  ${BOLD}${YELLOW}── Commit ───────────────────────────────────────${RESET}"
  local path_list
  path_list=$(printf "%s " "${processed_names[@]}")
  path_list="${path_list% }"
  local suggested_msg="chore: delete $path_list from repo and local"

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

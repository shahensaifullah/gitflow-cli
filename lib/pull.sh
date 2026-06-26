#!/bin/bash

# ═══════════════════════════════════════════════════
#  pull.sh — Pull latest code + conflict handler
#  Triggered by: gitflow --pull or gitflow --sync
#
#  Flow:
#  1. Fetch remote info
#  2. Show commits behind/ahead
#  3. Ask merge or rebase (with plain english explanation)
#  4. If conflicts found → offer 4 resolution options
#     [1] Take remote version
#     [2] Keep my version
#     [3] Fix manually → gitflow --continue
#     [4] Abort
# ═══════════════════════════════════════════════════

pull_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║           gitflow — Pull & Sync                ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  # Must be inside a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "  ${RED}✗ Not a git repository.${RESET}"
    echo -e "  ${DIM}Navigate to a project folder first.${RESET}"
    exit 1
  fi

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  echo -e "  ${DIM}Fetching latest from GitHub...${RESET}"
  git fetch origin 2>/dev/null

  BEHIND=$(git rev-list --count HEAD..origin/$CURRENT_BRANCH 2>/dev/null || echo "0")
  AHEAD=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD 2>/dev/null || echo "0")

  echo ""
  echo -e "${BOLD}${YELLOW}── Status ───────────────────────────────────────${RESET}"
  echo -e "  Branch         : ${CYAN}$CURRENT_BRANCH${RESET}"
  echo -e "  Commits behind : ${RED}$BEHIND${RESET}  ${DIM}(new commits on GitHub you don't have yet)${RESET}"
  echo -e "  Commits ahead  : ${GREEN}$AHEAD${RESET}  ${DIM}(your local commits not pushed yet)${RESET}"

  if [ "$BEHIND" -eq "0" ]; then
    echo ""
    echo -e "  ${GREEN}✓ Already up to date. Nothing to pull.${RESET}"
    echo ""
    exit 0
  fi

  # ── Merge or Rebase ─────────────────────────────
  echo ""
  echo -e "${BOLD}${YELLOW}── How do you want to sync? ─────────────────────${RESET}"
  echo ""
  echo -e "  ${CYAN}[1] Merge${RESET} ${GREEN}← recommended, press Enter to pick this${RESET}"
  echo -e "      → Grabs new code from GitHub and combines"
  echo -e "        it with your code. Both histories are kept."
  echo -e "        Think of it like: two rivers joining into one."
  echo -e "        ${GREEN}Safe for teams. Nothing gets lost.${RESET}"
  echo ""
  echo -e "  ${CYAN}[2] Rebase${RESET} ${DIM}← for experienced users only${RESET}"
  echo -e "      → Takes YOUR commits and moves them to the top,"
  echo -e "        as if you started AFTER the new code was pushed."
  echo -e "        Think of it like: cutting your work and"
  echo -e "        re-pasting it after the latest changes."
  echo -e "        ${RED}⚠ Can cause problems if others share your branch.${RESET}"
  echo ""
  echo -e "  ${CYAN}[3] Cancel${RESET}"
  echo ""
  echo -n "  Your choice (press Enter for Merge): "
  read SYNC_CHOICE

  if [ -z "$SYNC_CHOICE" ] || [ "$SYNC_CHOICE" == "1" ]; then
    echo ""
    echo -e "  ${CYAN}Merging latest code from origin/$CURRENT_BRANCH...${RESET}"
    git pull origin "$CURRENT_BRANCH" 2>&1
    PULL_RESULT=$?
  elif [ "$SYNC_CHOICE" == "2" ]; then
    echo ""
    echo -e "  ${CYAN}Rebasing on latest code from origin/$CURRENT_BRANCH...${RESET}"
    git pull --rebase origin "$CURRENT_BRANCH" 2>&1
    PULL_RESULT=$?
  elif [ "$SYNC_CHOICE" == "3" ]; then
    echo -e "  ${YELLOW}Cancelled. Nothing changed.${RESET}"
    exit 0
  else
    echo -e "  ${RED}✗ Invalid choice. Run gitflow --pull to try again.${RESET}"
    exit 1
  fi

  # ── Conflict Handler ─────────────────────────────
  if [ $PULL_RESULT -ne 0 ]; then
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)

    if [ -n "$CONFLICT_FILES" ]; then
      echo ""
      echo -e "  ${RED}⚠  Conflicts found in these files:${RESET}"
      INDEX=1
      CONFLICT_LIST=()
      while IFS= read -r file; do
        CONFLICT_LIST+=("$file")
        echo -e "    ${CYAN}[$INDEX]${RESET} $file"
        INDEX=$((INDEX + 1))
      done <<< "$CONFLICT_FILES"

      echo ""
      echo -e "  ${DIM}A conflict means: you and someone else both edited${RESET}"
      echo -e "  ${DIM}the same part of the same file. Git can't decide${RESET}"
      echo -e "  ${DIM}which version to keep — so you need to choose.${RESET}"
      echo ""
      echo -e "${BOLD}${YELLOW}── What do you want to do? ──────────────────────${RESET}"
      echo ""
      echo -e "  ${CYAN}[1] Take remote version${RESET}"
      echo -e "      → Overwrites YOUR local changes with the GitHub version."
      echo -e "        ${DIM}Use when: you don't need your local changes anymore.${RESET}"
      echo ""
      echo -e "  ${CYAN}[2] Keep my version${RESET}"
      echo -e "      → Ignores their changes, keeps YOUR local code."
      echo -e "        ${DIM}Use when: your local code is more up to date.${RESET}"
      echo ""
      echo -e "  ${CYAN}[3] Fix manually${RESET}"
      echo -e "      → Opens the conflict files so you can fix them yourself."
      echo -e "        Inside the file you'll see markers like:"
      echo -e "        ${DIM}<<<<<<< (your code)${RESET}"
      echo -e "        ${DIM}======= (separator)${RESET}"
      echo -e "        ${DIM}>>>>>>> (their code)${RESET}"
      echo -e "        Delete the markers, keep what you want, save the file."
      echo -e "        Then run: ${GREEN}gitflow --continue${RESET}"
      echo -e "        ${DIM}Use when: you need changes from both sides.${RESET}"
      echo ""
      echo -e "  ${CYAN}[4] Abort${RESET}"
      echo -e "      → Goes back to before the pull. Nothing changes."
      echo -e "        ${DIM}Use when: you're not sure what to do yet.${RESET}"
      echo ""
      echo -n "  Your choice: "
      read CONFLICT_CHOICE

      case "$CONFLICT_CHOICE" in
        1)
          echo ""
          echo -e "  ${CYAN}Taking remote version for conflict files...${RESET}"
          for file in "${CONFLICT_LIST[@]}"; do
            git checkout --theirs "$file"
            git add "$file"
            echo -e "  ${GREEN}✓ Took remote: $file${RESET}"
          done
          git commit -m "merge: took remote version for conflicts" > /dev/null 2>&1
          echo ""
          echo -e "  ${GREEN}✓ Sync complete. Remote version applied.${RESET}"
          ;;
        2)
          echo ""
          echo -e "  ${CYAN}Keeping your version for conflict files...${RESET}"
          for file in "${CONFLICT_LIST[@]}"; do
            git checkout --ours "$file"
            git add "$file"
            echo -e "  ${GREEN}✓ Kept yours: $file${RESET}"
          done
          git commit -m "merge: kept local version for conflicts" > /dev/null 2>&1
          echo ""
          echo -e "  ${GREEN}✓ Sync complete. Your version kept.${RESET}"
          ;;
        3)
          echo ""
          echo -e "  ${YELLOW}Opening conflict files...${RESET}"
          for file in "${CONFLICT_LIST[@]}"; do
            echo -e "  ${CYAN}→ $file${RESET}"
            if command -v code > /dev/null 2>&1; then
              code "$file"
            else
              echo -e "  ${DIM}Open this file manually in your editor.${RESET}"
            fi
          done
          echo ""
          echo -e "  ${YELLOW}Inside each file, look for these markers:${RESET}"
          echo -e "  ${DIM}<<<<<<< HEAD       ← your code starts here${RESET}"
          echo -e "  ${DIM}=======            ← separator${RESET}"
          echo -e "  ${DIM}>>>>>>> origin/... ← their code ends here${RESET}"
          echo ""
          echo -e "  ${YELLOW}Fix each file, save, then run:${RESET}"
          echo -e "  ${GREEN}  gitflow --continue${RESET}"
          echo ""
          exit 0
          ;;
        4)
          echo ""
          git merge --abort 2>/dev/null || git rebase --abort 2>/dev/null
          echo -e "  ${YELLOW}✓ Aborted. Everything is back to before the pull.${RESET}"
          exit 0
          ;;
        *)
          echo -e "  ${RED}✗ Invalid choice. Run gitflow --pull to try again.${RESET}"
          exit 1
          ;;
      esac

    else
      echo -e "  ${RED}✗ Pull failed.${RESET}"
      echo -e "  ${DIM}Possible reasons:${RESET}"
      echo -e "  ${DIM}• No internet connection${RESET}"
      echo -e "  ${DIM}• SSH key not set up${RESET}"
      echo -e "  ${DIM}• Branch doesn't exist on remote${RESET}"
      exit 1
    fi

  else
    echo ""
    echo -e "  ${GREEN}✓ Sync complete! Your code is up to date.${RESET}"
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    echo -e "  ${DIM}gitflow         → push your changes${RESET}"
    echo -e "  ${DIM}gitflow --help  → all commands${RESET}"
    echo ""
  fi
}
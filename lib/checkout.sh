#!/bin/bash

# ═══════════════════════════════════════════════════
#  checkout.sh — Smart branch checkout with pagination
#  and search. Optionally pull after switching.
#  Triggered by: gitflow --checkout
#               gitflow --checkout <branchname>
# ═══════════════════════════════════════════════════

checkout_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║         gitflow — Branch Checkout              ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "  ${RED}✗ Not a git repository.${RESET}"
    echo -e "  ${DIM}Navigate to a project folder first.${RESET}"
    exit 1
  fi

  # ── If branch name passed directly ──────────────
  # e.g. gitflow --checkout dev
  if [ -n "$1" ]; then
    TARGET_BRANCH="$1"
    _do_checkout "$TARGET_BRANCH"
    return
  fi

  # ── Fetch all branches ───────────────────────────
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  # Load all local + remote branches into array
  ALL_BRANCHES=()
  while IFS= read -r branch; do
    branch=$(echo "$branch" | sed 's/^[* ] //' | sed 's|remotes/origin/||' | xargs)
    # Skip HEAD pointer and duplicates
    if [[ "$branch" == "HEAD"* ]]; then continue; fi
    if [[ " ${ALL_BRANCHES[*]} " == *" $branch "* ]]; then continue; fi
    ALL_BRANCHES+=("$branch")
  done < <(git branch -a 2>/dev/null | sort -u)

  TOTAL=${#ALL_BRANCHES[@]}

  if [ "$TOTAL" -eq 0 ]; then
    echo -e "  ${YELLOW}No branches found.${RESET}"
    exit 0
  fi

  # ── Show branches (paginated or all) ────────────
  PAGE_SIZE=10
  PAGE=0
  FILTERED_BRANCHES=("${ALL_BRANCHES[@]}")
  SEARCH_TERM=""

  while true; do
    TOTAL_FILTERED=${#FILTERED_BRANCHES[@]}
    TOTAL_PAGES=$(( (TOTAL_FILTERED + PAGE_SIZE - 1) / PAGE_SIZE ))
    START=$((PAGE * PAGE_SIZE))
    END=$((START + PAGE_SIZE))
    if [ "$END" -gt "$TOTAL_FILTERED" ]; then END=$TOTAL_FILTERED; fi

    echo -e "${BOLD}${YELLOW}── Branch Checkout ──────────────────────────────${RESET}"
    echo ""
    echo -e "  ${CYAN}[b] Create new branch${RESET}  ${DIM}← from main or any base${RESET}"
    echo -e "  ${CYAN}[s] Search branch${RESET}       ${DIM}← filter by name${RESET}"
    if [ -n "$SEARCH_TERM" ]; then
      echo -e "  ${CYAN}[c] Clear search${RESET}        ${DIM}← show all branches${RESET}"
    fi
    echo -e "  ${DIM}─────────────────────────────────────────────${RESET}"

    if [ -n "$SEARCH_TERM" ]; then
      echo -e "  ${DIM}Search: \"$SEARCH_TERM\" — $TOTAL_FILTERED result(s)${RESET}"
    else
      echo -e "  ${DIM}Showing $((START + 1))-$END of $TOTAL_FILTERED branches${RESET}"
    fi
    echo ""

    # Print current page
    DISPLAY_INDEX=1
    PAGE_BRANCHES=()
    for (( i=START; i<END; i++ )); do
      branch="${FILTERED_BRANCHES[$i]}"
      PAGE_BRANCHES+=("$branch")
      if [ "$branch" == "$CURRENT_BRANCH" ]; then
        echo -e "  ${CYAN}[$DISPLAY_INDEX]${RESET} $branch ${GREEN}(current)${RESET}"
      else
        echo -e "  ${CYAN}[$DISPLAY_INDEX]${RESET} $branch"
      fi
      DISPLAY_INDEX=$((DISPLAY_INDEX + 1))
    done

    echo ""

    # Navigation
    if [ "$TOTAL_FILTERED" -gt "$PAGE_SIZE" ]; then
      if [ "$PAGE" -gt 0 ]; then
        echo -e "  ${DIM}[p] Previous page${RESET}"
      fi
      if [ "$END" -lt "$TOTAL_FILTERED" ]; then
        echo -e "  ${DIM}[n] Next page${RESET}"
      fi
    fi
    echo -e "  ${DIM}[q] Cancel${RESET}"
    echo ""
    echo -e "  Type ${GREEN}number${RESET} to checkout, or a command above."
    echo -n "  Your choice: "
    read CHOICE

    case "$CHOICE" in
      b|B)
        # ── Create new branch ──────────────────────
        echo ""
        echo -e "${BOLD}${YELLOW}── Create New Branch ────────────────────────────${RESET}"
        echo -e "  ${DIM}Shortcuts: f/name → feature/name${RESET}"
        echo -e "  ${DIM}           b/name → bugfix/name${RESET}"
        echo -e "  ${DIM}           h/name → hotfix/name${RESET}"
        echo -e "  ${DIM}           r/name → release/name${RESET}"
        echo ""
        echo -n "  Branch name: "
        read NEW_BRANCH_INPUT

        if [ -z "$NEW_BRANCH_INPUT" ]; then
          echo -e "  ${RED}✗ No name given. Cancelled.${RESET}"
          echo ""
          continue
        fi

        # Apply prefix shortcuts
        case "$NEW_BRANCH_INPUT" in
          f/*) NEW_BRANCH="feature/${NEW_BRANCH_INPUT:2}" ;;
          b/*) NEW_BRANCH="bugfix/${NEW_BRANCH_INPUT:2}"  ;;
          h/*) NEW_BRANCH="hotfix/${NEW_BRANCH_INPUT:2}"  ;;
          r/*) NEW_BRANCH="release/${NEW_BRANCH_INPUT:2}" ;;
          *)   NEW_BRANCH="$NEW_BRANCH_INPUT"             ;;
        esac

        # Ask base branch
        echo ""
        echo -n "  Base branch (press Enter for 'main'): "
        read BASE_BRANCH
        if [ -z "$BASE_BRANCH" ]; then
          BASE_BRANCH="main"
        fi

        echo ""
        echo -e "  ${CYAN}Switching to '$BASE_BRANCH' first...${RESET}"
        git checkout "$BASE_BRANCH" 2>/dev/null
        if [ $? -ne 0 ]; then
          echo -e "  ${RED}✗ Could not switch to '$BASE_BRANCH'.${RESET}"
          echo ""
          continue
        fi

        echo -e "  ${CYAN}Creating '$NEW_BRANCH' from '$BASE_BRANCH'...${RESET}"
        git checkout -b "$NEW_BRANCH"
        if [ $? -eq 0 ]; then
          echo ""
          echo -e "  ${GREEN}✓ Created and switched to '$NEW_BRANCH'${RESET}"
          echo -e "  ${DIM}Based on: $BASE_BRANCH${RESET}"
          echo ""
          echo -e "  ${DIM}Run gitflow when ready to push this branch.${RESET}"
          echo ""
        else
          echo -e "  ${RED}✗ Failed to create branch '$NEW_BRANCH'.${RESET}"
          echo ""
        fi
        return
        ;;
      n)
        if [ "$END" -lt "$TOTAL_FILTERED" ]; then
          PAGE=$((PAGE + 1))
        else
          echo -e "  ${YELLOW}Already on last page.${RESET}"
        fi
        echo ""
        ;;
      p)
        if [ "$PAGE" -gt 0 ]; then
          PAGE=$((PAGE - 1))
        else
          echo -e "  ${YELLOW}Already on first page.${RESET}"
        fi
        echo ""
        ;;
      s)
        echo -n "  Search: "
        read SEARCH_TERM
        PAGE=0
        FILTERED_BRANCHES=()
        for branch in "${ALL_BRANCHES[@]}"; do
          if [[ "$branch" == *"$SEARCH_TERM"* ]]; then
            FILTERED_BRANCHES+=("$branch")
          fi
        done
        if [ ${#FILTERED_BRANCHES[@]} -eq 0 ]; then
          echo -e "  ${YELLOW}No branches match \"$SEARCH_TERM\". Showing all.${RESET}"
          FILTERED_BRANCHES=("${ALL_BRANCHES[@]}")
          SEARCH_TERM=""
        fi
        echo ""
        ;;
      c)
        SEARCH_TERM=""
        PAGE=0
        FILTERED_BRANCHES=("${ALL_BRANCHES[@]}")
        echo ""
        ;;
      q|Q|"")
        echo -e "  ${YELLOW}Cancelled.${RESET}"
        exit 0
        ;;
      [0-9]*)
        IDX=$((CHOICE - 1))
        if [ "$IDX" -ge 0 ] && [ "$IDX" -lt "${#PAGE_BRANCHES[@]}" ]; then
          TARGET_BRANCH="${PAGE_BRANCHES[$IDX]}"
          _do_checkout "$TARGET_BRANCH"
          return
        else
          echo -e "  ${RED}✗ Invalid number. Try again.${RESET}"
          echo ""
        fi
        ;;
      *)
        TARGET_BRANCH="$CHOICE"
        _do_checkout "$TARGET_BRANCH"
        return
        ;;
    esac
  done
}

# ── Internal: do the actual checkout + optional pull
_do_checkout() {
  local BRANCH="$1"
  local CURRENT_BRANCH
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  echo ""

  if [ "$BRANCH" == "$CURRENT_BRANCH" ]; then
    echo -e "  ${YELLOW}Already on '$BRANCH'.${RESET}"
  else
    git checkout "$BRANCH" 2>/dev/null
    if [ $? -ne 0 ]; then
      # Branch doesn't exist locally — try to create from remote or new
      echo -e "  ${YELLOW}Branch '$BRANCH' not found locally.${RESET}"
      echo -e "  ${DIM}Trying remote origin/$BRANCH...${RESET}"
      git checkout -b "$BRANCH" "origin/$BRANCH" 2>/dev/null
      if [ $? -ne 0 ]; then
        echo ""
        echo -e "  ${YELLOW}Not found on remote either.${RESET}"
        echo -n "  Create new branch '$BRANCH'? (y/n): "
        read CREATE_CONFIRM
        if [[ "$CREATE_CONFIRM" == "y" || "$CREATE_CONFIRM" == "Y" ]]; then
          git checkout -b "$BRANCH"
          echo -e "  ${GREEN}✓ Created and switched to '$BRANCH'${RESET}"
        else
          echo -e "  ${YELLOW}Cancelled.${RESET}"
          exit 0
        fi
        return
      fi
    fi
    echo -e "  ${GREEN}✓ Switched to '$BRANCH'${RESET}"
  fi

  # ── Ask to pull latest ───────────────────────────
  echo ""
  echo -n "  Pull latest code for '$BRANCH'? (y/n): "
  read PULL_CONFIRM

  if [[ "$PULL_CONFIRM" != "y" && "$PULL_CONFIRM" != "Y" ]]; then
    echo ""
    echo -e "  ${GREEN}✓ Ready to work on '$BRANCH'${RESET}"
    echo -e "  ${DIM}Run gitflow when ready to push.${RESET}"
    echo ""
    return
  fi

  # ── Fetch remote ──────────────────────────────────
  echo ""
  echo -e "  ${DIM}Fetching latest from origin/$BRANCH...${RESET}"
  git fetch origin 2>/dev/null

  BEHIND=$(git rev-list --count HEAD..origin/$BRANCH 2>/dev/null || echo "0")

  if [ "$BEHIND" -eq "0" ]; then
    echo -e "  ${GREEN}✓ Already up to date.${RESET}"
    echo ""
    echo -e "  ${GREEN}✓ Ready to work on '$BRANCH'${RESET}"
    echo ""
    return
  fi

  echo -e "  ${DIM}$BEHIND new commit(s) on remote.${RESET}"

  # ── Merge or Rebase ──────────────────────────────
  echo ""
  echo -e "${BOLD}${YELLOW}── How do you want to sync? ─────────────────────${RESET}"
  echo ""
  echo -e "  ${CYAN}[1] Merge${RESET} ${GREEN}← recommended, press Enter${RESET}"
  echo -e "      → Combines remote code with yours."
  echo -e "        Think of it like: two rivers joining into one."
  echo -e "        ${GREEN}Safe. Nothing gets lost.${RESET}"
  echo ""
  echo -e "  ${CYAN}[2] Rebase${RESET} ${DIM}← experienced users only${RESET}"
  echo -e "      → Moves YOUR commits on top of remote."
  echo -e "        Think of it like: cutting your work and"
  echo -e "        re-pasting it after the latest changes."
  echo -e "        ${RED}⚠ Avoid on shared branches.${RESET}"
  echo ""
  echo -e "  ${CYAN}[3] Skip${RESET}"
  echo ""
  echo -n "  Your choice (press Enter for Merge): "
  read SYNC_CHOICE

  if [ -z "$SYNC_CHOICE" ] || [ "$SYNC_CHOICE" == "1" ]; then
    echo ""
    echo -e "  ${CYAN}Merging...${RESET}"
    git pull origin "$BRANCH" 2>&1
    PULL_RESULT=$?
  elif [ "$SYNC_CHOICE" == "2" ]; then
    echo ""
    echo -e "  ${CYAN}Rebasing...${RESET}"
    git pull --rebase origin "$BRANCH" 2>&1
    PULL_RESULT=$?
  else
    echo -e "  ${YELLOW}Skipped pull.${RESET}"
    echo -e "  ${GREEN}✓ Ready to work on '$BRANCH'${RESET}"
    echo ""
    return
  fi

  if [ $PULL_RESULT -eq 0 ]; then
    echo ""
    echo -e "  ${GREEN}✓ Pulled latest code for '$BRANCH'${RESET}"
    echo -e "  ${GREEN}✓ Ready to work!${RESET}"
    echo ""
    echo -e "  ${DIM}Run gitflow when ready to push.${RESET}"
    echo ""
  else
    echo ""
    echo -e "  ${RED}⚠ Pull had conflicts.${RESET}"
    echo -e "  ${DIM}Run: gitflow --pull to handle conflicts.${RESET}"
    echo ""
  fi
}
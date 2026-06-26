#!/bin/bash

# ═══════════════════════════════════════════════════
#  push.sh — Main push flow
#  Triggered by: gpush (no flags)
#
#  Flow:
#  1. No repo found → offer init or clone
#  2. Safety check (ahead/behind)
#  3. File staging (pick files or all)
#  4. Commit message (suggest or custom)
#  5. Branch selection (pick, create, shortcuts)
#  6. Final summary + confirm
#  7. Push + show result
# ═══════════════════════════════════════════════════

push_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║             gpush — Smart Push               ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  IS_NEW_REPO=false

  # ── No git repo found ──────────────────────────
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠  No git repository found in this folder.${RESET}"
    echo ""
    echo -e "  ${BOLD}What do you want to do?${RESET}"
    echo ""
    echo -e "  ${CYAN}[1] Initialize new repo${RESET}"
    echo -e "      → Creates a fresh git repo here."
    echo -e "        ${DIM}Use when: starting a brand new project.${RESET}"
    echo ""
    echo -e "  ${CYAN}[2] Clone existing repo from GitHub${RESET}"
    echo -e "      → Downloads a project from GitHub to your laptop."
    echo -e "        ${DIM}Use when: joining a team or new machine.${RESET}"
    echo ""
    echo -e "  ${CYAN}[3] Cancel${RESET}"
    echo ""
    echo -n "  Your choice: "
    read NO_REPO_CHOICE

    case "$NO_REPO_CHOICE" in
      1)
        init_flow
        IS_NEW_REPO=true
        ;;
      2)
        clone_flow
        exit 0
        ;;
      3|"")
        echo -e "  ${YELLOW}Cancelled.${RESET}"
        exit 0
        ;;
      *)
        echo -e "  ${RED}✗ Invalid choice. Aborting.${RESET}"
        exit 1
        ;;
    esac
  fi

  # ── Safety: ahead/behind check ────────────────
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  if [ "$IS_NEW_REPO" = false ]; then
    echo -e "  ${DIM}Fetching remote info...${RESET}"
    git fetch origin 2>/dev/null

    AHEAD=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD 2>/dev/null || echo "0")
    BEHIND=$(git rev-list --count HEAD..origin/$CURRENT_BRANCH 2>/dev/null || echo "0")

    echo ""
    echo -e "${BOLD}${YELLOW}── Status ───────────────────────────────────────${RESET}"
    echo -e "  Current branch : ${CYAN}$CURRENT_BRANCH${RESET}"
    echo -e "  Commits ahead  : ${GREEN}$AHEAD${RESET}"
    echo -e "  Commits behind : ${RED}$BEHIND${RESET}"

    if [ "$BEHIND" -gt "0" ]; then
      echo ""
      echo -e "  ${RED}⚠  Remote has $BEHIND newer commit(s) you don't have.${RESET}"
      echo -e "  ${DIM}Recommended: run gpush --pull first to avoid conflicts.${RESET}"
      echo ""
      echo -n "  Continue anyway? (y/n): "
      read CONTINUE_ANYWAY
      if [[ "$CONTINUE_ANYWAY" != "y" && "$CONTINUE_ANYWAY" != "Y" ]]; then
        echo -e "  ${YELLOW}Run: gpush --pull to get latest changes first.${RESET}"
        exit 0
      fi
    fi
  else
    AHEAD=0
    BEHIND=0
  fi

  # ── File staging ──────────────────────────────
  echo ""
  echo -e "${BOLD}${YELLOW}── Changed Files ────────────────────────────────${RESET}"

  CHANGED_FILES=()
  while IFS= read -r line; do
    CHANGED_FILES+=("$line")
  done < <(git status --porcelain | grep -v '^$')

  if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    echo -e "  ${YELLOW}Nothing to commit. Make some changes first.${RESET}"
    echo -e "  ${DIM}Run gpush --help to see all commands.${RESET}"
    exit 0
  fi

  INDEX=1
  FILE_NAMES=()
  for entry in "${CHANGED_FILES[@]}"; do
    STATUS="${entry:0:2}"
    FILEPATH="${entry:3}"
    FILE_NAMES+=("$FILEPATH")

    case "${STATUS:0:1}${STATUS:1:1}" in
      "M "|" M"|"MM") LABEL="Modified " ;;
      "A "|"AM")      LABEL="New file " ;;
      "D "|" D")      LABEL="Deleted  " ;;
      "R "|"RM")      LABEL="Renamed  " ;;
      "??")           LABEL="Untracked" ;;
      *)              LABEL="Changed  " ;;
    esac

    if [[ "$LABEL" != "Deleted  " ]]; then
      STATS=$(git diff --numstat HEAD -- "$FILEPATH" 2>/dev/null | awk '{printf "+%-4s -%s", $1, $2}')
      if [ -z "$STATS" ]; then
        STATS=$(git diff --numstat -- "$FILEPATH" 2>/dev/null | awk '{printf "+%-4s -%s", $1, $2}')
      fi
    else
      STATS=""
    fi

    printf "  ${CYAN}[%d]${RESET} ${GREEN}%s${RESET}  %-38s ${DIM}%s${RESET}\n" \
      "$INDEX" "$LABEL" "$FILEPATH" "$STATS"
    INDEX=$((INDEX + 1))
  done

  echo ""
  echo -e "  ${DIM}Select files to stage:${RESET}"
  echo -e "  • Press ${GREEN}Enter${RESET}       → stage ALL files"
  echo -e "  • Type ${GREEN}1${RESET} or ${GREEN}1 3${RESET}   → stage by number"
  echo ""
  echo -n "  Your selection: "
  read FILE_SELECTION

  if [ -z "$FILE_SELECTION" ]; then
    git add .
    echo -e "  ${GREEN}✓ All files staged.${RESET}"
    STAGED_NAMES="all files"
  else
    STAGED_NAMES=""
    for NUM in $FILE_SELECTION; do
      IDX=$((NUM - 1))
      if [ "$IDX" -ge 0 ] && [ "$IDX" -lt "${#FILE_NAMES[@]}" ]; then
        git add "${FILE_NAMES[$IDX]}"
        echo -e "  ${GREEN}✓ Staged: ${FILE_NAMES[$IDX]}${RESET}"
        STAGED_NAMES="$STAGED_NAMES ${FILE_NAMES[$IDX]}"
      else
        echo -e "  ${RED}✗ Invalid number: $NUM${RESET}"
      fi
    done
  fi

  if git diff --cached --quiet; then
    echo -e "  ${RED}✗ Nothing staged. Aborting.${RESET}"
    exit 1
  fi

  # ── Commit message ────────────────────────────
  echo ""
  echo -e "${BOLD}${YELLOW}── Commit Message ───────────────────────────────${RESET}"

  RECENT_COMMITS=$(git log --oneline -3 2>/dev/null)
  if [ -n "$RECENT_COMMITS" ]; then
    echo -e "  ${DIM}Recent commits:${RESET}"
    echo "$RECENT_COMMITS" | while read -r line; do
      echo -e "  ${DIM}  • $line${RESET}"
    done
  fi

  if [ "$STAGED_NAMES" == "all files" ]; then
    CHANGED_LIST=$(git diff --cached --name-only | tr '\n' ' ' | sed 's/ $//')
  else
    CHANGED_LIST=$(echo "$STAGED_NAMES" | xargs -n1 basename 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
  fi
  SUGGESTED_MSG="update $CHANGED_LIST"

  echo ""
  echo -e "  ${DIM}Suggested: \"$SUGGESTED_MSG\"${RESET}"
  echo -e "  Press ${GREEN}Enter${RESET} to accept, or type your own."
  echo ""
  echo -n "  Commit message: "
  read COMMIT_MSG

  if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="$SUGGESTED_MSG"
  fi

  git commit -m "$COMMIT_MSG" > /dev/null 2>&1
  echo -e "  ${GREEN}✓ Committed: \"$COMMIT_MSG\"${RESET}"

  # ── Branch selection ──────────────────────────
  echo ""
  echo -e "${BOLD}${YELLOW}── Branch ───────────────────────────────────────${RESET}"

  BRANCHES=()
  INDEX=1
  while IFS= read -r branch; do
    branch=$(echo "$branch" | sed 's/^[* ] //' | xargs)
    BRANCHES+=("$branch")
    if [ "$branch" == "$CURRENT_BRANCH" ]; then
      echo -e "  ${CYAN}[$INDEX]${RESET} $branch ${GREEN}(current)${RESET}"
    else
      echo -e "  ${CYAN}[$INDEX]${RESET} $branch"
    fi
    INDEX=$((INDEX + 1))
  done < <(git branch 2>/dev/null)

  echo ""
  echo -e "  • Press ${GREEN}Enter${RESET}          → use current (${CYAN}$CURRENT_BRANCH${RESET})"
  echo -e "  • Type a ${GREEN}number${RESET}         → pick from list"
  echo -e "  • Type ${GREEN}f/name${RESET}           → creates feature/name"
  echo -e "  • Type ${GREEN}b/name${RESET}           → creates bugfix/name"
  echo -e "  • Type ${GREEN}h/name${RESET}           → creates hotfix/name"
  echo -e "  • Type ${GREEN}r/name${RESET}           → creates release/name"
  echo -e "  • Type ${GREEN}any-name${RESET}         → creates that branch"
  echo ""
  echo -n "  Branch selection: "
  read BRANCH_INPUT

  if [ -z "$BRANCH_INPUT" ]; then
    TARGET_BRANCH="$CURRENT_BRANCH"
  elif [[ "$BRANCH_INPUT" =~ ^[0-9]+$ ]]; then
    IDX=$((BRANCH_INPUT - 1))
    if [ "$IDX" -ge 0 ] && [ "$IDX" -lt "${#BRANCHES[@]}" ]; then
      TARGET_BRANCH="${BRANCHES[$IDX]}"
    else
      echo -e "  ${RED}✗ Invalid number. Using current branch.${RESET}"
      TARGET_BRANCH="$CURRENT_BRANCH"
    fi
  else
    case "$BRANCH_INPUT" in
      f/*) TARGET_BRANCH="feature/${BRANCH_INPUT:2}" ;;
      b/*) TARGET_BRANCH="bugfix/${BRANCH_INPUT:2}"  ;;
      h/*) TARGET_BRANCH="hotfix/${BRANCH_INPUT:2}"  ;;
      r/*) TARGET_BRANCH="release/${BRANCH_INPUT:2}" ;;
      *)   TARGET_BRANCH="$BRANCH_INPUT"             ;;
    esac
    echo -e "  ${CYAN}Creating branch: $TARGET_BRANCH${RESET}"
    git checkout -b "$TARGET_BRANCH" 2>/dev/null || git checkout "$TARGET_BRANCH" 2>/dev/null
  fi

  if [[ "$TARGET_BRANCH" == "main" || "$TARGET_BRANCH" == "master" ]]; then
    echo ""
    echo -e "  ${RED}⚠  WARNING: Pushing directly to '$TARGET_BRANCH'.${RESET}"
    echo -e "  ${DIM}This updates the main codebase everyone uses.${RESET}"
    echo -n "  Are you sure? (y/n): "
    read MAIN_CONFIRM
    if [[ "$MAIN_CONFIRM" != "y" && "$MAIN_CONFIRM" != "Y" ]]; then
      echo -e "  ${YELLOW}Aborted.${RESET}"
      exit 0
    fi
  fi

  # ── Final summary ─────────────────────────────
  echo ""
  echo -e "${BOLD}${YELLOW}── Push Summary ─────────────────────────────────${RESET}"
  echo -e "  Files   : ${CYAN}$STAGED_NAMES${RESET}"
  echo -e "  Message : ${CYAN}\"$COMMIT_MSG\"${RESET}"
  echo -e "  Branch  : ${CYAN}$TARGET_BRANCH${RESET}"
  if [ "$IS_NEW_REPO" = true ]; then
    echo -e "  Type    : ${YELLOW}First push (-u origin main)${RESET}"
  else
    echo -e "  Ahead   : ${GREEN}$((AHEAD + 1)) commit(s)${RESET}"
  fi
  echo ""
  echo -n "  Confirm push? (y/n): "
  read FINAL_CONFIRM

  if [[ "$FINAL_CONFIRM" != "y" && "$FINAL_CONFIRM" != "Y" ]]; then
    echo -e "  ${YELLOW}Aborted. Commit saved locally but not pushed.${RESET}"
    echo -e "  ${DIM}Run gpush again when ready to push.${RESET}"
    exit 0
  fi

  # ── Push ──────────────────────────────────────
  echo ""
  echo -e "  ${CYAN}Pushing to origin/$TARGET_BRANCH...${RESET}"

  if [ "$IS_NEW_REPO" = true ]; then
    git push -u origin "$TARGET_BRANCH" 2>&1
  else
    git push origin "$TARGET_BRANCH" 2>&1
  fi

  if [ $? -eq 0 ]; then
    COMMIT_HASH=$(git rev-parse --short HEAD)
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)

    if [[ "$REMOTE_URL" == *"github.com"* ]]; then
      GITHUB_URL=$(echo "$REMOTE_URL" \
        | sed 's/git@github.com:/https:\/\/github.com\//' \
        | sed 's/\.git$//')
      BRANCH_URL="$GITHUB_URL/tree/$TARGET_BRANCH"
    else
      BRANCH_URL="$REMOTE_URL"
    fi

    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║  ✓ Push Successful!                          ║${RESET}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}Commit hash :${RESET} ${CYAN}$COMMIT_HASH${RESET}"
    echo -e "  ${BOLD}Branch      :${RESET} ${CYAN}$TARGET_BRANCH${RESET}"
    echo -e "  ${BOLD}URL         :${RESET} ${CYAN}$BRANCH_URL${RESET}"
    echo ""

    LOG_ENTRY="[$(date '+%Y-%m-%d %H:%M:%S')]  branch=$TARGET_BRANCH  commit=$COMMIT_HASH  msg=\"$COMMIT_MSG\""
    echo "$LOG_ENTRY" >> "$HISTORY_FILE"

    echo -e "  ${DIM}Logged to ~/.gpush_history${RESET}"
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    echo -e "  ${DIM}gpush --pull   → sync latest from GitHub${RESET}"
    echo -e "  ${DIM}gpush --log    → view push history${RESET}"
    echo -e "  ${DIM}gpush --help   → all commands${RESET}"
    echo ""

  else
    echo ""
    echo -e "  ${RED}✗ Push failed.${RESET}"
    echo -e "  ${DIM}Possible reasons:${RESET}"
    echo -e "  ${DIM}• Run gpush --pull to sync first${RESET}"
    echo -e "  ${DIM}• Check your internet or SSH key${RESET}"
    echo -e "  ${DIM}• Remote URL may be wrong — check: git remote -v${RESET}"
    exit 1
  fi
}

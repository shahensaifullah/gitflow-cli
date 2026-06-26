#!/bin/bash

# ═══════════════════════════════════════════════════
#  gpush — Interactive Git Add, Commit & Push Tool
#  Usage:  gpush           → interactive push
#          gpush --help    → full documentation
#          gpush --log     → view push history
# ═══════════════════════════════════════════════════

HISTORY_FILE="$HOME/.gpush_history"

# ── Colors ────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ══════════════════════════════════════════════════
#  HELP DOCUMENTATION
# ══════════════════════════════════════════════════
show_help() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║        gpush — Smart Git Push Tool           ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "${BOLD}USAGE:${RESET}"
  echo -e "  ${GREEN}gpush${RESET}           Run the interactive git push flow"
  echo -e "  ${GREEN}gpush --help${RESET}    Show this documentation"
  echo -e "  ${GREEN}gpush --log${RESET}     View your push history"
  echo ""
  echo -e "${BOLD}${YELLOW}── NEW REPO INITIALIZATION ─────────────────────${RESET}"
  echo -e "  If no git repo exists in the current folder,"
  echo -e "  gpush will offer to initialize one for you."
  echo ""
  echo -e "  It will:"
  echo -e "  • Run ${CYAN}git init${RESET}"
  echo -e "  • Set default branch to ${CYAN}main${RESET}"
  echo -e "  • Ask for your GitHub remote URL (SSH or HTTPS)"
  echo -e "  • Run ${CYAN}git remote add origin <url>${RESET}"
  echo -e "  • Use ${CYAN}git push -u origin main${RESET} for first push"
  echo ""
  echo -e "  ${BOLD}Supported URL formats:${RESET}"
  echo -e "  ${DIM}SSH   : git@github.com:username/repo.git${RESET}"
  echo -e "  ${DIM}HTTPS : https://github.com/username/repo.git${RESET}"
  echo ""
  echo -e "${BOLD}${YELLOW}── GROUP 1: Smart File Staging ─────────────────${RESET}"
  echo -e "  Lists every changed file with status and diff stats."
  echo ""
  echo -e "  ${BOLD}How to select files:${RESET}"
  echo -e "  • Press ${GREEN}Enter${RESET}         → stage ALL files"
  echo -e "  • Type ${GREEN}1${RESET}              → stage only file 1"
  echo -e "  • Type ${GREEN}1 3${RESET}            → stage files 1 and 3"
  echo ""
  echo -e "${BOLD}${YELLOW}── GROUP 2: Smart Commit Message ───────────────${RESET}"
  echo -e "  Shows last 3 commits and auto-suggests a message."
  echo ""
  echo -e "  ${BOLD}How to use:${RESET}"
  echo -e "  • Press ${GREEN}Enter${RESET}         → accept the suggestion"
  echo -e "  • Type your own    → override with custom message"
  echo ""
  echo -e "${BOLD}${YELLOW}── GROUP 3: Branch Handling ─────────────────────${RESET}"
  echo -e "  Lists all branches as a numbered menu."
  echo ""
  echo -e "  ${BOLD}How to select branch:${RESET}"
  echo -e "  • Press ${GREEN}Enter${RESET}         → use your current branch"
  echo -e "  • Type ${GREEN}2${RESET}              → switch to branch #2"
  echo -e "  • Type ${GREEN}new-branch${RESET}     → creates and pushes new branch"
  echo ""
  echo -e "  ${RED}Warning:${RESET} Pushing to ${BOLD}main${RESET} asks for confirmation."
  echo ""
  echo -e "${BOLD}${YELLOW}── GROUP 4: Safety Checks ───────────────────────${RESET}"
  echo -e "  • Checks if remote has newer commits (pull warning)"
  echo -e "  • Shows commits ahead/behind before pushing"
  echo -e "  • Final summary with ${GREEN}y/n${RESET} confirmation"
  echo ""
  echo -e "${BOLD}${YELLOW}── GROUP 5: After Push Info ─────────────────────${RESET}"
  echo -e "  • Shows commit hash after push"
  echo -e "  • Shows GitHub URL of pushed branch"
  echo -e "  • Logs push to ${CYAN}~/.gpush_history${RESET}"
  echo ""
  echo -e "  ${BOLD}View push history:${RESET}"
  echo -e "  ${GREEN}gpush --log${RESET}"
  echo ""
  echo -e "${BOLD}${YELLOW}── EXAMPLES ─────────────────────────────────────${RESET}"
  echo -e "  ${CYAN}gpush${RESET}             ${DIM}→ full interactive flow${RESET}"
  echo -e "  ${CYAN}gpush --log${RESET}       ${DIM}→ see push history${RESET}"
  echo -e "  ${CYAN}gpush --help${RESET}      ${DIM}→ show this documentation${RESET}"
  echo ""
  echo -e "${DIM}═══════════════════════════════════════════════${RESET}"
  echo ""
}

# ══════════════════════════════════════════════════
#  PUSH LOG VIEWER
# ══════════════════════════════════════════════════
show_log() {
  echo ""
  echo -e "${BOLD}${CYAN}Push History — ~/.gpush_history${RESET}"
  echo -e "${DIM}───────────────────────────────────────────────${RESET}"
  if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
    echo -e "${YELLOW}No push history yet. Run gpush to start.${RESET}"
  else
    cat "$HISTORY_FILE"
  fi
  echo -e "${DIM}───────────────────────────────────────────────${RESET}"
  echo ""
}

# ── Handle flags ──────────────────────────────────
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
  exit 0
fi

if [[ "$1" == "--log" || "$1" == "-l" ]]; then
  show_log
  exit 0
fi

# ══════════════════════════════════════════════════
#  MAIN FLOW
# ══════════════════════════════════════════════════

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║             gpush — Smart Push               ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""

# ══════════════════════════════════════════════════
#  INIT FLOW — if no git repo found
# ══════════════════════════════════════════════════
IS_NEW_REPO=false

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠  No git repository found in this folder.${RESET}"
  echo ""
  echo -n "  Initialize a new git repo here? (y/n): "
  read INIT_CONFIRM

  if [[ "$INIT_CONFIRM" != "y" && "$INIT_CONFIRM" != "Y" ]]; then
    echo -e "${RED}✗ Aborted. Navigate to a git project folder and try again.${RESET}"
    exit 0
  fi

  # git init
  git init
  echo -e "  ${GREEN}✓ Git initialized.${RESET}"

  # set default branch to main
  git checkout -b main 2>/dev/null || git symbolic-ref HEAD refs/heads/main
  echo -e "  ${GREEN}✓ Default branch set to main.${RESET}"

  # ask for remote URL
  echo ""
  echo -e "  ${BOLD}Paste your GitHub remote URL:${RESET}"
  echo -e "  ${DIM}SSH   example: git@github.com:shahensaifullah/repo.git${RESET}"
  echo -e "  ${DIM}HTTPS example: https://github.com/shahensaifullah/repo.git${RESET}"
  echo ""
  echo -n "  Remote URL: "
  read REMOTE_URL

  if [ -z "$REMOTE_URL" ]; then
    echo -e "${RED}✗ No remote URL provided. You can add it later with:${RESET}"
    echo -e "${DIM}  git remote add origin <url>${RESET}"
  else
    git remote add origin "$REMOTE_URL"
    echo -e "  ${GREEN}✓ Remote origin added: $REMOTE_URL${RESET}"
  fi

  IS_NEW_REPO=true
  echo ""
fi

# ══════════════════════════════════════════════════
#  GROUP 4: Safety — ahead/behind check
# ══════════════════════════════════════════════════
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$IS_NEW_REPO" = false ]; then
  echo -e "${DIM}  Fetching remote info...${RESET}"
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
    echo -e "  ${RED}⚠  Remote has $BEHIND newer commit(s). Pull recommended.${RESET}"
    echo -e "  ${DIM}Run: git pull origin $CURRENT_BRANCH${RESET}"
    echo ""
    echo -n "  Continue anyway? (y/n): "
    read CONTINUE_ANYWAY
    if [[ "$CONTINUE_ANYWAY" != "y" && "$CONTINUE_ANYWAY" != "Y" ]]; then
      echo -e "${YELLOW}  Aborted. Run: git pull origin $CURRENT_BRANCH${RESET}"
      exit 0
    fi
  fi
else
  AHEAD=0
  BEHIND=0
  echo -e "${BOLD}${YELLOW}── Status ───────────────────────────────────────${RESET}"
  echo -e "  Current branch : ${CYAN}$CURRENT_BRANCH${RESET}"
  echo -e "  ${DIM}New repository — first push${RESET}"
fi

# ══════════════════════════════════════════════════
#  GROUP 1: Smart file staging
# ══════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${YELLOW}── Changed Files ────────────────────────────────${RESET}"

CHANGED_FILES=()
while IFS= read -r line; do
  CHANGED_FILES+=("$line")
done < <(git status --porcelain | grep -v '^$')

if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
  echo -e "  ${YELLOW}Nothing to commit. Make some changes first.${RESET}"
  echo -e "  ${DIM}Tip: Run gpush --help to see usage.${RESET}"
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

  if [[ "$LABEL" != "Deleted  " && "$LABEL" != "Untracked" ]]; then
    STATS=$(git diff --numstat HEAD -- "$FILEPATH" 2>/dev/null | awk '{printf "+%-4s -%s", $1, $2}')
    if [ -z "$STATS" ]; then
      STATS=$(git diff --numstat -- "$FILEPATH" 2>/dev/null | awk '{printf "+%-4s -%s", $1, $2}')
    fi
  else
    STATS=""
  fi

  printf "  ${CYAN}[%d]${RESET} ${GREEN}%s${RESET}  %-38s ${DIM}%s${RESET}\n" "$INDEX" "$LABEL" "$FILEPATH" "$STATS"
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
  echo -e "  ${RED}✗ Nothing was staged. Aborting.${RESET}"
  exit 1
fi

# ══════════════════════════════════════════════════
#  GROUP 2: Smart commit message
# ══════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════
#  GROUP 3: Branch selection
# ══════════════════════════════════════════════════
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
echo -e "  • Type a ${GREEN}new name${RESET}       → create and push new branch"
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
  TARGET_BRANCH="$BRANCH_INPUT"
  echo -e "  ${CYAN}Creating new branch: $TARGET_BRANCH${RESET}"
  git checkout -b "$TARGET_BRANCH" 2>/dev/null || git checkout "$TARGET_BRANCH" 2>/dev/null
fi

if [[ "$TARGET_BRANCH" == "main" || "$TARGET_BRANCH" == "master" ]]; then
  echo ""
  echo -e "  ${RED}⚠  WARNING: Pushing directly to '$TARGET_BRANCH'.${RESET}"
  echo -n "  Are you sure? (y/n): "
  read MAIN_CONFIRM
  if [[ "$MAIN_CONFIRM" != "y" && "$MAIN_CONFIRM" != "Y" ]]; then
    echo -e "  ${YELLOW}Aborted. No changes were pushed.${RESET}"
    exit 0
  fi
fi

# ══════════════════════════════════════════════════
#  GROUP 4: Final confirmation summary
# ══════════════════════════════════════════════════
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
  exit 0
fi

# ══════════════════════════════════════════════════
#  PUSH
# ══════════════════════════════════════════════════
echo ""
echo -e "${CYAN}  Pushing to origin/$TARGET_BRANCH...${RESET}"

if [ "$IS_NEW_REPO" = true ]; then
  git push -u origin "$TARGET_BRANCH" 2>&1
else
  git push origin "$TARGET_BRANCH" 2>&1
fi

if [ $? -eq 0 ]; then

  # ════════════════════════════════════════════════
  #  GROUP 5: After push info
  # ════════════════════════════════════════════════
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
  echo -e "  ${DIM}View history anytime: gpush --log${RESET}"
  echo ""

else
  echo ""
  echo -e "  ${RED}✗ Push failed.${RESET}"
  echo -e "  ${DIM}Possible reasons:${RESET}"
  echo -e "  ${DIM}• Run: git pull origin $TARGET_BRANCH (remote has newer commits)${RESET}"
  echo -e "  ${DIM}• Check your internet or SSH key${RESET}"
  echo -e "  ${DIM}• Remote URL may be wrong — check: git remote -v${RESET}"
  exit 1
fi
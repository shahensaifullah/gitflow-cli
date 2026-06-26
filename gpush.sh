#!/bin/bash

# ═══════════════════════════════════════════════════
#  gpush — Interactive Git Tool
#  Commands:
#    gpush              → push flow (init/clone if no repo)
#    gpush --pull       → pull latest from GitHub
#    gpush --sync       → same as --pull
#    gpush --continue   → finish after manual conflict fix
#    gpush --clone      → clone a repo
#    gpush --log        → view push history
#    gpush --help       → full documentation
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
#  HELP
# ══════════════════════════════════════════════════
show_help() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║          gpush — Smart Git Tool              ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "${BOLD}COMMANDS:${RESET}"
  echo -e "  ${GREEN}gpush${RESET}              Push your code to GitHub"
  echo -e "                     If no repo found, offers to init or clone"
  echo -e "  ${GREEN}gpush --pull${RESET}       Pull latest code from GitHub"
  echo -e "  ${GREEN}gpush --sync${RESET}       Same as --pull"
  echo -e "  ${GREEN}gpush --continue${RESET}   Finish push after fixing conflicts manually"
  echo -e "  ${GREEN}gpush --clone${RESET}      Clone a GitHub repo to your laptop"
  echo -e "  ${GREEN}gpush --log${RESET}        View your push history"
  echo -e "  ${GREEN}gpush --help${RESET}       Show this documentation"
  echo ""
  echo -e "${BOLD}${YELLOW}── WHEN NO GIT REPO FOUND ──────────────────────${RESET}"
  echo -e "  Running ${CYAN}gpush${RESET} in a folder with no git repo will ask:"
  echo ""
  echo -e "  ${DIM}[1] Initialize new repo${RESET}"
  echo -e "  ${DIM}    → Fresh git repo, set remote URL, first push${RESET}"
  echo -e "  ${DIM}[2] Clone existing repo from GitHub${RESET}"
  echo -e "  ${DIM}    → Download a project from GitHub to your laptop${RESET}"
  echo ""
  echo -e "${BOLD}${YELLOW}── PUSHING (gpush) ─────────────────────────────${RESET}"
  echo -e "  ${BOLD}Step 1 — File staging:${RESET}"
  echo -e "  Shows all changed files with a number."
  echo -e "  • Press ${GREEN}Enter${RESET}       → stage ALL files"
  echo -e "  • Type ${GREEN}1${RESET} or ${GREEN}1 3${RESET}   → stage specific files by number"
  echo ""
  echo -e "  ${BOLD}Step 2 — Commit message:${RESET}"
  echo -e "  Shows last 3 commits and suggests a message."
  echo -e "  • Press ${GREEN}Enter${RESET}       → accept suggestion"
  echo -e "  • Type your own   → use custom message"
  echo ""
  echo -e "  ${BOLD}Step 3 — Branch:${RESET}"
  echo -e "  Lists all branches as a numbered menu."
  echo -e "  • Press ${GREEN}Enter${RESET}       → use current branch"
  echo -e "  • Type ${GREEN}number${RESET}       → pick from list"
  echo -e "  • Type ${GREEN}new-name${RESET}     → creates new branch"
  echo -e "  • Type ${GREEN}f/login${RESET}      → creates feature/login"
  echo -e "  • Type ${GREEN}b/login${RESET}      → creates bugfix/login"
  echo -e "  • Type ${GREEN}h/login${RESET}      → creates hotfix/login"
  echo ""
  echo -e "  ${BOLD}Step 4 — Safety:${RESET}"
  echo -e "  Shows summary. Asks ${GREEN}y/n${RESET} before pushing."
  echo -e "  Warns if pushing directly to main or master."
  echo ""
  echo -e "${BOLD}${YELLOW}── PULLING (gpush --pull) ──────────────────────${RESET}"
  echo -e "  Fetches latest code from GitHub."
  echo -e "  Offers two sync methods:"
  echo ""
  echo -e "  ${BOLD}[1] Merge${RESET} (recommended)"
  echo -e "  Grabs new code and combines it with yours."
  echo -e "  Think of it like: two rivers joining into one."
  echo -e "  Safe for teams. Nothing gets lost."
  echo ""
  echo -e "  ${BOLD}[2] Rebase${RESET} (experienced users)"
  echo -e "  Moves YOUR commits on top of the new code."
  echo -e "  Think of it like: cutting your work and"
  echo -e "  re-pasting it after the latest changes."
  echo -e "  ${RED}⚠ Avoid on shared/public branches.${RESET}"
  echo ""
  echo -e "  ${BOLD}If conflicts are found:${RESET}"
  echo -e "  [1] Take remote version  → overwrite with GitHub version"
  echo -e "  [2] Keep my version      → ignore their changes"
  echo -e "  [3] Fix manually         → fix in editor, then run gpush --continue"
  echo -e "  [4] Abort                → go back to before the pull"
  echo ""
  echo -e "${BOLD}${YELLOW}── AFTER PUSH ──────────────────────────────────${RESET}"
  echo -e "  Shows commit hash, GitHub branch URL."
  echo -e "  Logs every push to ${CYAN}~/.gpush_history${RESET}"
  echo -e "  View history: ${GREEN}gpush --log${RESET}"
  echo ""
  echo -e "${DIM}════════════════════════════════════════════════${RESET}"
  echo ""
}

# ══════════════════════════════════════════════════
#  LOG VIEWER
# ══════════════════════════════════════════════════
show_log() {
  echo ""
  echo -e "${BOLD}${CYAN}Push History — ~/.gpush_history${RESET}"
  echo -e "${DIM}────────────────────────────────────────────────${RESET}"
  if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
    echo -e "${YELLOW}  No push history yet. Run gpush to start.${RESET}"
  else
    cat "$HISTORY_FILE"
  fi
  echo -e "${DIM}────────────────────────────────────────────────${RESET}"
  echo ""
}

# ══════════════════════════════════════════════════
#  CLONE FLOW
# ══════════════════════════════════════════════════
clone_flow() {
  echo ""
  echo -e "${BOLD}${YELLOW}── Clone a GitHub Repo ──────────────────────────${RESET}"
  echo -e "  ${DIM}SSH   example: git@github.com:username/repo.git${RESET}"
  echo -e "  ${DIM}HTTPS example: https://github.com/username/repo.git${RESET}"
  echo ""
  echo -n "  Paste GitHub URL: "
  read CLONE_URL

  if [ -z "$CLONE_URL" ]; then
    echo -e "  ${RED}✗ No URL provided. Aborting.${RESET}"
    exit 1
  fi

  echo ""
  echo -n "  Clone into which folder? (press Enter for current folder): "
  read CLONE_DIR

  echo ""
  if [ -z "$CLONE_DIR" ]; then
    echo -e "  ${CYAN}Cloning into current folder...${RESET}"
    git clone "$CLONE_URL"
  else
    echo -e "  ${CYAN}Cloning into $CLONE_DIR...${RESET}"
    git clone "$CLONE_URL" "$CLONE_DIR"
  fi

  if [ $? -eq 0 ]; then
    REPO_NAME=$(basename "$CLONE_URL" .git)
    DEST="${CLONE_DIR:-$REPO_NAME}"
    echo ""
    echo -e "  ${GREEN}✓ Clone successful!${RESET}"
    echo -e "  ${BOLD}Go into your project:${RESET}"
    echo -e "  ${CYAN}  cd $DEST${RESET}"
    echo ""
  else
    echo ""
    echo -e "  ${RED}✗ Clone failed.${RESET}"
    echo -e "  ${DIM}Check your URL or SSH key setup.${RESET}"
    exit 1
  fi
}

# ══════════════════════════════════════════════════
#  PULL / SYNC FLOW
# ══════════════════════════════════════════════════
pull_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║           gpush — Pull & Sync                ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗ Not a git repository.${RESET}"
    echo -e "${DIM}  Navigate to a project folder first.${RESET}"
    exit 1
  fi

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  echo -e "${DIM}  Fetching latest from GitHub...${RESET}"
  git fetch origin 2>/dev/null

  BEHIND=$(git rev-list --count HEAD..origin/$CURRENT_BRANCH 2>/dev/null || echo "0")
  AHEAD=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD 2>/dev/null || echo "0")

  echo ""
  echo -e "${BOLD}${YELLOW}── Status ───────────────────────────────────────${RESET}"
  echo -e "  Branch         : ${CYAN}$CURRENT_BRANCH${RESET}"
  echo -e "  Commits behind : ${RED}$BEHIND${RESET}"
  echo -e "  Commits ahead  : ${GREEN}$AHEAD${RESET}"

  if [ "$BEHIND" -eq "0" ]; then
    echo ""
    echo -e "  ${GREEN}✓ Already up to date. Nothing to pull.${RESET}"
    echo ""
    exit 0
  fi

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
    echo -e "  ${CYAN}Merging latest code...${RESET}"
    git pull origin "$CURRENT_BRANCH" 2>&1
    PULL_RESULT=$?
  elif [ "$SYNC_CHOICE" == "2" ]; then
    echo ""
    echo -e "  ${CYAN}Rebasing on latest code...${RESET}"
    git pull --rebase origin "$CURRENT_BRANCH" 2>&1
    PULL_RESULT=$?
  elif [ "$SYNC_CHOICE" == "3" ]; then
    echo -e "  ${YELLOW}Cancelled. Nothing changed.${RESET}"
    exit 0
  else
    echo -e "  ${RED}✗ Invalid choice. Aborting.${RESET}"
    exit 1
  fi

  # ── Check for conflicts ──────────────────────────
  if [ $PULL_RESULT -ne 0 ]; then
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)

    if [ -n "$CONFLICT_FILES" ]; then
      echo ""
      echo -e "  ${RED}⚠  Conflicts found in:${RESET}"
      INDEX=1
      CONFLICT_LIST=()
      while IFS= read -r file; do
        CONFLICT_LIST+=("$file")
        echo -e "    ${CYAN}[$INDEX]${RESET} $file"
        INDEX=$((INDEX + 1))
      done <<< "$CONFLICT_FILES"

      echo ""
      echo -e "${BOLD}${YELLOW}── What do you want to do? ──────────────────────${RESET}"
      echo ""
      echo -e "  ${CYAN}[1] Take remote version${RESET}"
      echo -e "      → Overwrites YOUR local changes with the GitHub version."
      echo -e "        ${DIM}Use when: you don't need your local changes anymore.${RESET}"
      echo ""
      echo -e "  ${CYAN}[2] Keep my version${RESET}"
      echo -e "      → Ignores their changes, keeps YOUR local code."
      echo -e "        ${DIM}Use when: your code is more up to date.${RESET}"
      echo ""
      echo -e "  ${CYAN}[3] Fix manually${RESET}"
      echo -e "      → Opens conflict files in your editor."
      echo -e "        Fix the conflicts, then run: ${GREEN}gpush --continue${RESET}"
      echo -e "        ${DIM}Use when: you need changes from both sides.${RESET}"
      echo ""
      echo -e "  ${CYAN}[4] Abort${RESET}"
      echo -e "      → Goes back to before the pull. Nothing changes."
      echo ""
      echo -n "  Your choice: "
      read CONFLICT_CHOICE

      case "$CONFLICT_CHOICE" in
        1)
          echo ""
          echo -e "  ${CYAN}Taking remote version for all conflict files...${RESET}"
          for file in "${CONFLICT_LIST[@]}"; do
            git checkout --theirs "$file"
            git add "$file"
            echo -e "  ${GREEN}✓ Took remote version: $file${RESET}"
          done
          git commit -m "merge: took remote version for conflicts" > /dev/null 2>&1
          echo ""
          echo -e "  ${GREEN}✓ Sync complete. Remote version applied.${RESET}"
          ;;
        2)
          echo ""
          echo -e "  ${CYAN}Keeping your version for all conflict files...${RESET}"
          for file in "${CONFLICT_LIST[@]}"; do
            git checkout --ours "$file"
            git add "$file"
            echo -e "  ${GREEN}✓ Kept your version: $file${RESET}"
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
              echo -e "  ${DIM}Open manually: $file${RESET}"
            fi
          done
          echo ""
          echo -e "  ${YELLOW}Fix the conflicts marked with <<<<<<< in each file.${RESET}"
          echo -e "  ${YELLOW}Then run: ${GREEN}gpush --continue${RESET}"
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
          echo -e "  ${RED}✗ Invalid choice. Run gpush --pull to try again.${RESET}"
          exit 1
          ;;
      esac
    else
      echo -e "  ${RED}✗ Pull failed.${RESET}"
      echo -e "  ${DIM}Check your internet or SSH key setup.${RESET}"
      exit 1
    fi
  else
    echo ""
    echo -e "  ${GREEN}✓ Sync complete! Your code is up to date.${RESET}"
    echo ""
  fi
}

# ══════════════════════════════════════════════════
#  CONTINUE FLOW (after manual conflict fix)
# ══════════════════════════════════════════════════
continue_flow() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║         gpush — Continue After Fix           ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗ Not a git repository.${RESET}"
    exit 1
  fi

  CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)
  if [ -n "$CONFLICT_FILES" ]; then
    echo -e "  ${RED}⚠  Still has unresolved conflicts:${RESET}"
    echo "$CONFLICT_FILES" | while read -r file; do
      echo -e "    ${RED}→ $file${RESET}"
    done
    echo ""
    echo -e "  ${YELLOW}Fix all conflict markers (<<<<<<< ======= >>>>>>>) in these files.${RESET}"
    echo -e "  ${YELLOW}Then run: ${GREEN}gpush --continue${RESET}${YELLOW} again.${RESET}"
    exit 1
  fi

  echo -e "  ${CYAN}Staging resolved files...${RESET}"
  git add .

  echo -n "  Commit message for merge fix (press Enter for default): "
  read FIX_MSG
  if [ -z "$FIX_MSG" ]; then
    FIX_MSG="merge: resolved conflicts"
  fi

  git commit -m "$FIX_MSG" > /dev/null 2>&1
  echo -e "  ${GREEN}✓ Committed: \"$FIX_MSG\"${RESET}"

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo ""
  echo -e "  ${CYAN}Pushing to origin/$CURRENT_BRANCH...${RESET}"
  git push origin "$CURRENT_BRANCH"

  if [ $? -eq 0 ]; then
    echo ""
    echo -e "  ${GREEN}✓ Done! Conflict resolved and pushed to origin/$CURRENT_BRANCH${RESET}"
    echo ""
  else
    echo -e "  ${RED}✗ Push failed. Check your connection or branch.${RESET}"
    exit 1
  fi
}

# ══════════════════════════════════════════════════
#  INIT FLOW (new repo)
# ══════════════════════════════════════════════════
init_flow() {
  echo ""
  echo -e "${BOLD}${YELLOW}── Initialize New Repo ──────────────────────────${RESET}"

  git init
  echo -e "  ${GREEN}✓ Git initialized.${RESET}"

  git checkout -b main 2>/dev/null || git symbolic-ref HEAD refs/heads/main
  echo -e "  ${GREEN}✓ Default branch set to main.${RESET}"

  echo ""
  echo -e "  ${BOLD}Paste your GitHub remote URL:${RESET}"
  echo -e "  ${DIM}SSH   : git@github.com:username/repo.git${RESET}"
  echo -e "  ${DIM}HTTPS : https://github.com/username/repo.git${RESET}"
  echo ""
  echo -n "  Remote URL: "
  read REMOTE_URL

  if [ -z "$REMOTE_URL" ]; then
    echo -e "  ${YELLOW}⚠ No remote URL added. You can add later:${RESET}"
    echo -e "  ${DIM}git remote add origin <url>${RESET}"
  else
    git remote add origin "$REMOTE_URL"
    echo -e "  ${GREEN}✓ Remote origin added.${RESET}"
  fi
  echo ""
}

# ══════════════════════════════════════════════════
#  HANDLE FLAGS
# ══════════════════════════════════════════════════
case "$1" in
  --help|-h)    show_help;     exit 0 ;;
  --log|-l)     show_log;      exit 0 ;;
  --clone)      clone_flow;    exit 0 ;;
  --pull|--sync) pull_flow;   exit 0 ;;
  --continue)   continue_flow; exit 0 ;;
esac

# ══════════════════════════════════════════════════
#  MAIN PUSH FLOW
# ══════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║             gpush — Smart Push               ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""

IS_NEW_REPO=false

# ── No git repo found ─────────────────────────────
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
  echo -e "        ${DIM}Use when: joining a team or setting up on a new machine.${RESET}"
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
    echo -e "  ${RED}⚠  Remote has $BEHIND newer commit(s).${RESET}"
    echo -e "  ${DIM}Run: gpush --pull to sync first.${RESET}"
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
  echo -e "  ${DIM}Tip: Run gpush --help to see all commands.${RESET}"
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
  echo -e "  ${RED}✗ Nothing staged. Aborting.${RESET}"
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
#  GROUP 3: Branch selection with shortcuts
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
echo -e "  • Type ${GREEN}f/name${RESET}           → creates feature/name"
echo -e "  • Type ${GREEN}b/name${RESET}           → creates bugfix/name"
echo -e "  • Type ${GREEN}h/name${RESET}           → creates hotfix/name"
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
  # Branch prefix shortcuts
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
  echo -n "  Are you sure? (y/n): "
  read MAIN_CONFIRM
  if [[ "$MAIN_CONFIRM" != "y" && "$MAIN_CONFIRM" != "Y" ]]; then
    echo -e "  ${YELLOW}Aborted.${RESET}"
    exit 0
  fi
fi

# ══════════════════════════════════════════════════
#  GROUP 4: Final summary
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
echo -e "  ${CYAN}Pushing to origin/$TARGET_BRANCH...${RESET}"

if [ "$IS_NEW_REPO" = true ]; then
  git push -u origin "$TARGET_BRANCH" 2>&1
else
  git push origin "$TARGET_BRANCH" 2>&1
fi

if [ $? -eq 0 ]; then

  # ════════════════════════════════════════════════
  #  GROUP 5: After push
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
  echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
  echo -e "  ${DIM}gpush --pull    → sync latest from GitHub${RESET}"
  echo -e "  ${DIM}gpush --log     → view push history${RESET}"
  echo -e "  ${DIM}gpush --help    → all commands${RESET}"
  echo ""

else
  echo ""
  echo -e "  ${RED}✗ Push failed.${RESET}"
  echo -e "  ${DIM}Try: gpush --pull to sync first${RESET}"
  echo -e "  ${DIM}Or check your internet / SSH key${RESET}"
  exit 1
fi
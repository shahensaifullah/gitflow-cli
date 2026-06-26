# gitflow-cli 🚀

An interactive CLI tool that replaces the repetitive `git add . && git commit -m "" && git push` cycle with a smart, guided terminal experience.

![Shell](https://img.shields.io/badge/Shell-Bash-green?style=flat-square&logo=gnubash)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## What it does

Instead of running three commands every time you push, just run:

```bash
gpush
```

It guides you through everything — staging files, writing a commit message, picking a branch, pulling latest code, handling conflicts, and more. All in one interactive terminal flow.

---

## Installation

### Step 1 — Clone the repo

```bash
git clone git@github.com:shahensaifullah/gitflow-cli.git or git clone https://github.com/shahensaifullah/gitflow-cli.git
cd smart-git-push
```

### Step 2 — Run the installer

```bash
bash install.sh
```

The installer will:
- Copy all files to `~/.gpush/`
- Create a symlink at `~/.local/bin/gpush`
- Automatically add PATH to your `.zshrc` or `.bashrc`

### Step 3 — Reload your terminal

```bash
source ~/.zshrc
# or
source ~/.bashrc
```

### Step 4 — Verify

```bash
which gpush
# Expected: /Users/yourname/.local/bin/gpush
```

---

## Project Structure

```
smart-git-push/
├── gpush.sh          ← main entry point (thin router)
├── install.sh        ← one command installer
├── README.md
├── .gitignore
└── lib/
    ├── colors.sh     ← color variables used across all files
    ├── help.sh       ← gpush --help documentation
    ├── log.sh        ← gpush --log history viewer
    ├── init.sh       ← new repo initialization
    ├── clone.sh      ← gpush --clone flow
    ├── pull.sh       ← gpush --pull / --sync + conflict handler
    ├── continue.sh   ← gpush --continue after manual conflict fix
    └── push.sh       ← main push flow
```

---

## Commands

| Command | Description |
|---|---|
| `gpush` | Full interactive push flow. Offers init or clone if no repo found. |
| `gpush --pull` | Pull latest code from GitHub with merge or rebase |
| `gpush --sync` | Same as `--pull` |
| `gpush --clone` | Clone any GitHub repo to your laptop |
| `gpush --continue` | Finish push after fixing conflicts manually |
| `gpush --log` | View your push history |
| `gpush --help` | Full documentation |

---

## Push Flow

Running `gpush` in a project folder:

```
╔══════════════════════════════════════════════╗
║             gpush — Smart Push               ║
╚══════════════════════════════════════════════╝

  Fetching remote info...

── Status ───────────────────────────────────────
  Current branch : main
  Commits ahead  : 0
  Commits behind : 0

── Changed Files ────────────────────────────────
  [1] Modified   src/views.py        +12  -3
  [2] New file   README.md           +5   -0
  [3] Deleted    src/old_utils.py    -40  -0

  • Press Enter       → stage ALL files
  • Type 1 or 1 3    → stage specific files by number

  Your selection: 1 2

── Commit Message ────────────────────────────────
  Recent commits:
    • fix login bug
    • update readme

  Suggested: "update views.py README.md"
  Commit message: fix user auth flow

── Branch ───────────────────────────────────────
  [1] main (current)
  [2] dev
  [3] feature/auth

  • Press Enter         → use current branch (main)
  • Type a number       → pick from list
  • Type f/name         → creates feature/name
  • Type b/name         → creates bugfix/name
  • Type h/name         → creates hotfix/name
  • Type any-name       → creates that branch

  Branch selection: 2

── Push Summary ─────────────────────────────────
  Files   : src/views.py README.md
  Message : "fix user auth flow"
  Branch  : dev
  Ahead   : 1 commit(s)

  Confirm push? (y/n): y

╔══════════════════════════════════════════════╗
║  ✓ Push Successful!                          ║
╚══════════════════════════════════════════════╝

  Commit hash : a3f9c12
  Branch      : dev
  URL         : https://github.com/shahensaifullah/smart-git-push/tree/dev
  Logged to ~/.gpush_history
```

---

## No Repo Found Flow

Running `gpush` in a folder with no git repo:

```
⚠  No git repository found in this folder.

  What do you want to do?

  [1] Initialize new repo
      → Creates a fresh git repo here.
        Use when: starting a brand new project.

  [2] Clone existing repo from GitHub
      → Downloads a project from GitHub to your laptop.
        Use when: joining a team or setting up on a new machine.

  [3] Cancel
```

Picking **[1]** runs `git init`, sets `main` as default branch, asks for your GitHub remote URL, and continues into the push flow automatically.

Picking **[2]** asks for the GitHub URL (SSH or HTTPS) and clones the repo.

---

## Pull & Sync Flow

```bash
gpush --pull
# or
gpush --sync
```

```
╔══════════════════════════════════════════════╗
║           gpush — Pull & Sync                ║
╚══════════════════════════════════════════════╝

  Fetching latest from GitHub...

── Status ───────────────────────────────────────
  Branch         : main
  Commits behind : 3  (new commits on GitHub you don't have yet)
  Commits ahead  : 1  (your local commits not pushed yet)

── How do you want to sync? ─────────────────────

  [1] Merge  ← recommended, press Enter to pick this
      → Grabs new code from GitHub and combines
        it with your code. Both histories are kept.
        Think of it like: two rivers joining into one.
        Safe for teams. Nothing gets lost.

  [2] Rebase  ← for experienced users only
      → Takes YOUR commits and moves them to the top,
        as if you started AFTER the new code was pushed.
        Think of it like: cutting your work and
        re-pasting it after the latest changes.
        ⚠ Can cause problems if others share your branch.

  [3] Cancel

  Your choice (press Enter for Merge):
```

---

## Conflict Handler

If a pull causes conflicts, gpush walks you through fixing them:

```
  ⚠  Conflicts found in these files:
    [1] src/views.py
    [2] src/models.py

  A conflict means: you and someone else both edited
  the same part of the same file. Git can't decide
  which version to keep — so you need to choose.

── What do you want to do? ──────────────────────

  [1] Take remote version
      → Overwrites YOUR local changes with the GitHub version.
        Use when: you don't need your local changes anymore.

  [2] Keep my version
      → Ignores their changes, keeps YOUR local code.
        Use when: your local code is more up to date.

  [3] Fix manually
      → Opens conflict files in your editor.
        Fix the conflicts, then run: gpush --continue
        Use when: you need changes from both sides.

  [4] Abort
      → Goes back to before the pull. Nothing changes.
```

After fixing conflicts manually, finish with:

```bash
gpush --continue
```

---

## Clone Flow

```bash
gpush --clone
```

```
── Clone a GitHub Repo ──────────────────────────
  SSH   example: git@github.com:username/repo.git
  HTTPS example: https://github.com/username/repo.git

  Paste GitHub URL: git@github.com:shahensaifullah/smart-git-push.git

  Clone into which folder? (press Enter for current folder):

  ✓ Clone successful!
  Go into your project:
    cd smart-git-push
```

---

## Branch Shortcuts

When selecting a branch during `gpush`, you can use shortcuts:

| Type | Creates |
|---|---|
| `f/login` | `feature/login` |
| `b/login` | `bugfix/login` |
| `h/login` | `hotfix/login` |
| `r/v2` | `release/v2` |
| `any-name` | `any-name` |

---

## Push History

Every push is logged automatically to `~/.gpush_history`.

View it anytime:

```bash
gpush --log
```

```
[2024-12-01 14:23:10]  branch=main  commit=a3f9c12  msg="fix login bug"
[2024-12-02 09:11:45]  branch=dev   commit=b2e8d31  msg="add user profile"
[2024-12-03 11:05:22]  branch=main  commit=c9f1e44  msg="update readme"
```

---

## Features Summary

| Feature | Description |
|---|---|
| Smart file staging | Pick specific files or stage all with Enter |
| Diff stats | See lines added/removed per file |
| Commit suggestion | Auto-suggests message based on changed files |
| Recent commits | Shows last 3 commits so you don't repeat yourself |
| Branch menu | Pick branch by number or create new with shortcuts |
| Main branch warning | Warns before pushing to main or master |
| Safety check | Shows ahead/behind count before pushing |
| Final confirmation | Full summary before every push |
| Init flow | Create new repo + set remote from terminal |
| Clone flow | Clone any GitHub repo from terminal |
| Pull & sync | Merge or rebase with plain English explanation |
| Conflict handler | 4 options: take remote, keep mine, fix manually, abort |
| Continue flow | Finish after manual conflict resolution |
| Push history | Every push logged with date, branch, commit, message |
| GitHub URL | Shows direct link to pushed branch after every push |

---

## Requirements

- `bash` or `zsh`
- `git` installed and configured
- A remote repository (GitHub, GitLab, Bitbucket, etc.)

---

## Compatibility

| Platform | Supported |
|---|---|
| macOS (zsh) | ✅ |
| macOS (bash) | ✅ |
| Linux (bash) | ✅ |
| Linux (zsh) | ✅ |
| Windows (WSL) | ✅ |
| Windows (Git Bash) | ✅ |

---

## License

MIT — free to use, modify, and share.

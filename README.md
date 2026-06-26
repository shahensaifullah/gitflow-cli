# smart-git-push 🚀

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

It will guide you through everything:

1. Shows all changed files — you pick which ones to stage
2. Suggests a commit message — accept or write your own
3. Lists all branches — pick by number or create a new one
4. Warns you before pushing to `main`
5. Shows a final summary before confirming the push
6. Displays commit hash, GitHub URL, and logs the push to history

---

## Installation

### Step 1 — Download the script

Clone the repo or download `gpush.sh` directly:

```bash
git clone https://github.com/yourusername/smart-git-push.git
cd smart-git-push
```

### Step 2 — Install the script

```bash
mkdir -p ~/.local/bin
cp gpush.sh ~/.local/bin/gpush
chmod +x ~/.local/bin/gpush
```

### Step 3 — Add to PATH

Add this line to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

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

## Usage

| Command | Description |
|---|---|
| `gpush` | Run the full interactive push flow |
| `gpush --help` | Show full documentation |
| `gpush --log` | View your push history |

---

## Full Interactive Flow

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
    • init project

  Suggested: "update views.py README.md"
  Press Enter to accept, or type your own message.

  Commit message: fix user auth flow

── Branch ───────────────────────────────────────
  [1] main (current)
  [2] dev
  [3] feature/auth

  • Press Enter         → use current branch (main)
  • Type a number       → pick from list
  • Type a new name     → creates and pushes new branch

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
  URL         : https://github.com/you/repo/tree/dev
  Logged to ~/.gpush_history
```

---

## Features

### Group 1 — Smart File Staging

Shows every changed file with its status and diff stats (lines added/removed). You can stage all files or pick specific ones by number.

```
[1] Modified   src/views.py     +12  -3
[2] New file   README.md        +5   -0
[3] Deleted    old_utils.py     -40  -0

Your selection: 1 3       ← stages only views.py and old_utils.py
```

### Group 2 — Smart Commit Message

Displays your last 3 commit messages so you don't repeat yourself. Auto-suggests a commit message based on the files you staged. Press Enter to accept or type your own.

```
Recent commits:
  • fix login bug
  • update readme

Suggested: "update views.py README.md"
Commit message:              ← press Enter to use suggestion
```

### Group 3 — Branch Handling

Lists all local branches as a numbered menu. You can pick by number, press Enter to use the current branch, or type a brand new branch name to create it on the spot.

```
[1] main (current)
[2] dev
[3] feature/auth

Branch selection: new-feature     ← creates and pushes new branch
```

Pushing directly to `main` or `master` triggers a warning and requires confirmation.

### Group 4 — Safety Checks

Before anything happens, `gpush` fetches remote info and tells you:
- How many commits ahead you are
- How many commits behind you are (and warns you to pull first)

Before pushing, it shows a full summary and asks for final `y/n` confirmation.

### Group 5 — After Push Info

After a successful push you get:
- Short commit hash
- Direct GitHub URL to the branch
- Entry logged to `~/.gpush_history`

View your full push history anytime:

```bash
gpush --log
```

Output:
```
[2024-12-01 14:23:10]  branch=main  commit=a3f9c12  msg="fix login bug"
[2024-12-02 09:11:45]  branch=dev   commit=b2e8d31  msg="add user profile"
```

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

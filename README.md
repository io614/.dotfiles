# .dotfiles

My dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package  | Files           |
|----------|-----------------|
| `git`    | `.gitconfig`    |
| `sqlite` | `.sqliterc`     |
| `tmux`   | `.tmux.conf`    |
| `vim`    | `.vimrc`        |

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/io614/.dotfiles/main/install.sh | bash
```

This will:
1. Install `git` and `stow` if missing
2. Clone the repo to `~/.dotfiles`
3. Stow all packages into `$HOME`

## Manual Install

```bash
git clone https://github.com/io614/.dotfiles ~/.dotfiles
cd ~/.dotfiles
stow git sqlite tmux vim
```

## Usage

```bash
# Install all packages
bash install.sh

# Preview without making changes
bash install.sh --dry-run

# Only specific packages
bash install.sh tmux vim

# Refresh symlinks (e.g. after pulling updates)
bash install.sh --restow

# Remove symlinks for a package
bash install.sh --delete tmux
```

## How It Works

Each top-level directory is a Stow *package*. Running `stow <package>` creates
symlinks in `$HOME` mirroring the package's directory structure.

```
~/.dotfiles/vim/.vimrc  →  symlink at  ~/.vimrc
~/.dotfiles/tmux/.tmux.conf  →  symlink at  ~/.tmux.conf
```

Edits to the files in `$HOME` are actually edits inside the repo — so changes
are tracked by git automatically.

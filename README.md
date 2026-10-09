# dotfiles

[![ci](https://github.com/fjug/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/fjug/dotfiles/actions/workflows/ci.yml)

Florian Jug's shell and tool configuration — macOS and Linux, zsh and bash,
from one tree.

```bash
git clone https://github.com/fjug/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

The repo is named `dotfiles`; it is cloned to `~/.dotfiles`. `bootstrap.sh`
detects the platform and is safe to re-run. If something looks wrong,
`install/doctor.sh` says what and how to fix it.

## How it fits together

```
shell/          sourced by BOTH zsh and bash, on both platforms
  env.sh          platform detection, EDITOR/PAGER/LESS, XDG, colours, locale
  aliases.sh      every alias that is not shell-specific
  functions.sh    mkcd, extract, git-latexdiff, scratch, diff, version
zsh/            00-options 10-path 20-completion 30-plugins 40-tools
                50-aliases 60-functions 70-keybindings
bash/           00-lib 10-path 20-options 30-completion 40-prompt
                50-tools 60-aliases 70-functions 90-conda
config/         starship.toml, bat/config
install/
  lib.sh          logging, platform detection, idempotent linking
  packages.sh     Homebrew, or a Linux package manager + linux-tools.sh
  linux-tools.sh  pinned, SHA-256-verified release binaries into ~/.local
  python-uv.sh    uv, managed interpreters, global tools
  ssh-setup.sh    ~/.ssh permissions, load keys into the agent
  vim-plugins.sh  pathogen bundles under .vim/bundle/
  macos-defaults.sh
  doctor.sh       read-only diagnosis
bootstrap.sh    one command for a new machine
link.sh         symlinks, idempotent
Brewfile        macOS CLI baseline     Brewfile.apps   macOS GUI apps
docs/           NEW-MACHINE.md, conda-to-uv.md, linux-tools.md
```

The `shell/` directory is the point of the layout: aliases and functions are
written once, in a dialect that parses in zsh, bash 5.x and the bash 3.2 that
macOS still ships. `zsh/` and `bash/` hold only what is genuinely specific to
one shell. Both get the same starship prompt, the same tools, the same vi
editing mode and the same muscle memory.

## Platforms

**macOS.** zsh is the login shell (Homebrew's, not Apple's 5.9). `Brewfile` is
the CLI baseline; `Brewfile.apps` mirrors the GUI apps. MacTeX is deliberately
not in the baseline — it is a 6.4 GB download, so `brew install --cask mactex`
or `DOTFILES_TEX=1` when you want it.

**Linux.** bash is the shell. Where there is root, `install/packages.sh` uses
apt/dnf/pacman/zypper. Where there is not — the VDI, an HPC login node —
`install/linux-tools.sh` fetches pinned, SHA-256-verified release binaries
into `~/.local`, links completions and man pages, and touches no rc file. See
[docs/linux-tools.md](docs/linux-tools.md).

**Anywhere.** Every tool integration is guarded. On a bare login node you get
a git-aware fallback prompt and bash's own history search, and nothing errors.

## Design decisions

**One shared core, two shells.** See `shell/` above. The alternative — a bash
config that drifts from the zsh one — is what this repo had before.

**No zsh plugin manager.** `zsh/30-plugins.zsh` git-clones four plugins into
`~/.local/share/zsh/plugins` on first run and sources them.
`dotfiles-update-plugins` pulls them.

**bash start-up is cached.** `starship`, `zoxide` and `fzf` init cost ~100 ms
of process spawns per shell. `_cached_init` writes the generated code to
`~/.cache/bash-init/` and rebuilds only when the binary or config is newer.
`_starship_init` additionally rewrites `$(starship time)` — one spawn at
start-up plus two per command — into bash's own `$EPOCHREALTIME`. Completions
for `uv`, `uvx` and `gh` are generated to files so bash-completion lazy-loads
them on first <Tab>. This matters on a CPU-throttled VDI, where a fork can
cost 0.1 s.

**uv for Python; conda only where it still exists.** No conda, mamba or pyenv
is installed by anything here, and `uv` manages the interpreters, so there is
no `brew install python` either. The pip/conda guardrails in `shell/aliases.sh`
switch themselves off on a machine that has conda, because the Linux boxes
still depend on it, and `bash/90-conda.bash` initialises it there — guarded, so
a conda-free machine pays nothing. Migration notes:
[docs/conda-to-uv.md](docs/conda-to-uv.md).

**Machine-specific things stay out of git.** `~/.zshrc.local`,
`~/.bashrc.local` and `~/.gitconfig.local` are sourced last and are not
tracked. `link.sh` creates them, and puts the git-lfs filter in the last one
only where git-lfs exists — a `required = true` lfs filter breaks every
checkout on a machine without it.

**Nothing is version pinned, except where it must be.** The Brewfile lists
names. `install/linux-tools.sh` pins version *and* SHA-256, because it
downloads release binaries over the network.

## Changing something

```bash
install/selftest.sh
```

Parses every file under every shell that reads it — including the bash 3.2
macOS ships — runs `link.sh` against a throwaway `$HOME`, starts zsh and both
bashes interactively and fails on any error they print, then runs `doctor.sh`.
CI runs this exact script on ubuntu and macOS, so a green badge means what a
green local run means.

It exists because the two things that have actually broken here were invisible
locally: a shared file that stopped parsing in one shell, and
`shopt -s autocd` erroring only on macOS's bash 3.2, which silently cost
`/bin/bash` its prompt, zoxide and fzf.

After upgrading tools by hand, `dotfiles-clear-cache` drops the generated init
code and completions so the next shell regenerates them.

## Everyday commands

| | |
|---|---|
| `dotfiles` | cd here |
| `dotfiles-sync` | git pull + re-link |
| `dotfiles-update-plugins` | pull each zsh plugin |
| `zshconfig` / `bashconfig` | edit the respective rc |
| `z <fragment>` | jump to a frecent directory (zoxide) |
| `^R` / `^T` / `⌥C` | fzf history / files / cd |
| `lg` | lazygit |
| `scratch [pkg...]` | throwaway uv project in a temp dir |
| `extract <archive>` | unpack anything |
| `git-latexdiff <f.tex> <n>` | diff a paper against `HEAD~n`, open the PDF |
| `version` | what OS is this, really |

## Keeping machines in sync

```bash
dotfiles-sync && dotfiles-update-plugins
# macOS
brew update && brew upgrade && brew bundle --file=~/.dotfiles/Brewfile
# Linux
~/.dotfiles/install/linux-tools.sh
# both
uv tool upgrade --all
```

Add a package on one machine, add it to `Brewfile` or `install/linux-tools.sh`,
commit. That is what keeps them from drifting.

## History

This repo is the consolidation of two that ran in parallel for a decade:

- **`fjug/.dotfiles`** (this one, since renamed) — own repo, 2016, macOS/zsh,
  carrying the 2026 modernization: oh-my-zsh and conda out, starship and uv in.
- **`fjug/dotfiles`** — a fork of [ctrueden/dotfiles](https://github.com/ctrueden/dotfiles),
  2010, 562 commits, Linux/bash, carrying the 2026 VDI setup, which was itself
  a translation of the Mac zsh config into bash.

They were merged with `--allow-unrelated-histories`, so all 562 commits and
their authorship — Curtis Rueden's included — are in `git log` here. The merge
commit is the boundary; anything removed in the consolidation (the modular
`vimrc.d/`, `mrconfig` and its ~60 dead Java repositories, `zshrc`'s zgen
setup) is recoverable from it.

Tags: `pre-cleanup-2026` is the state before the Mac modernization,
`pre-consolidation-2026` the state before this merge.

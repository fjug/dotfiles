# .dotfiles

Florian Jug's shell and tool configuration. macOS first, Linux where it makes
sense (the shell config, git, and vim work on both; the Brewfiles and the
`defaults write` script are macOS only).

```bash
git clone https://github.com/fjug/.dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

Full checklist for a fresh machine: [docs/NEW-MACHINE.md](docs/NEW-MACHINE.md).

## What's here

```
bootstrap.sh          one-command setup for a new machine
link.sh               symlink configs into $HOME (idempotent)
Brewfile              CLI baseline — formulae + the few casks that are tooling
Brewfile.apps         GUI applications, mirroring the old machine
install/
  lib.sh              shared helpers (logging, platform detection, linking)
  packages.sh         Homebrew, or a Linux package-manager fallback
  python-uv.sh        uv, managed interpreters, global tools
  macos-defaults.sh   system preferences (opt-in, read before running)
zsh/                  the actual shell config, sourced in numeric order
  00-options.zsh      history, globbing, directory stack
  10-path.zsh         PATH, Homebrew shellenv, optional tool dirs
  20-completion.zsh   compinit with a once-a-day cache rebuild
  30-plugins.zsh      autosuggestions, syntax highlighting, history search
  40-tools.zsh        starship, zoxide, fzf, bat, uv, gh, ssh-agent
  50-aliases.zsh
  60-functions.zsh
  70-keybindings.zsh
config/starship.toml  prompt
ssh/config.example    template — the real ~/.ssh/config is never committed
docs/                 new-machine checklist, conda→uv migration
.zshrc .zshenv .bashrc .vimrc .vim/ .inputrc .gitconfig .gitignore_global
```

## Design decisions

**No plugin manager.** `zsh/30-plugins.zsh` git-clones four plugins into
`~/.local/share/zsh/plugins` on first run and sources them. Same behaviour on
macOS and Linux, nothing to update but git. `dotfiles-update-plugins` pulls them.

**uv only, no conda.** There is no conda, mamba, or pyenv anywhere in this repo,
and `install/python-uv.sh` warns if it finds one. `uv` manages the interpreters
too, so there's no `brew install python` either. Migration notes:
[docs/conda-to-uv.md](docs/conda-to-uv.md).

**Machine-specific things stay out of git.** `~/.zshrc.local` is sourced last
and is not tracked — licences, work-only hosts, and anything that shouldn't be
public go there. Same for `~/.bashrc.local` and `~/.ssh/config`.

**Guarded, not assumed.** Every tool integration in `zsh/40-tools.zsh` checks
whether the tool exists first, so the same config works on an HPC login node
where you can't install anything. Without starship you get a vcs_info prompt;
without fzf, `^R` falls back to zsh's incremental search.

**Nothing is version pinned.** The Brewfile lists names, not versions, so a
fresh install always lands on current releases.

## Everyday commands

| | |
|---|---|
| `dotfiles` | cd here |
| `dotfiles-sync` | git pull + re-link |
| `dotfiles-update-plugins` | pull each zsh plugin |
| `zshconfig` | edit `.zshrc` |
| `z <fragment>` | jump to a frecent directory (zoxide) |
| `^R` / `^T` / `⌥C` | fzf history / files / cd |
| `lg` | lazygit |
| `scratch [pkg...]` | throwaway uv project in a temp dir |
| `extract <archive>` | unpack anything |
| `git-latexdiff <f.tex> <n>` | diff a paper against `HEAD~n`, open the PDF |

## History

The pre-2026 state is tagged `pre-cleanup-2026`. It carried a large amount of
inherited configuration from a 2012-era fork — `mrconfig` with ~60 dead Java
repositories, `plugins/*.sh` full of ImageJ/LOCI/Maven aliases, a `cwd/`
bookmark system, MacPorts and Anaconda paths for a user that no longer exists.
All of that is gone. The `.vim/` tree was kept as it was, deliberately.

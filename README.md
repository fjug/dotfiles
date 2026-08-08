# .dotfiles

Florian Jug's shell and tool configuration. macOS first, Linux where it makes
sense (the shell config, git, and vim work on both; the Brewfiles and the
`defaults write` script are macOS only).

---

## Installing on a new Mac

### 1. Clone and bootstrap

Nothing needs installing first — `git` triggers the Xcode Command Line Tools
prompt on its own. Use HTTPS here, since your SSH keys aren't on the machine
yet; step 4 switches the remote over.

```bash
git clone https://github.com/fjug/.dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap.sh
```

`bootstrap.sh` asks for confirmation once, then runs four steps:

1. **packages** — installs Homebrew, then everything in `Brewfile`
2. **symlinks** — links every config into `$HOME`, backing up anything real it
   finds in the way
3. **python** — installs uv, managed Python 3.11/3.12/3.13, and the global tools
4. **shell** — offers to make zsh the login shell, then pre-fetches the zsh
   plugins so your first real terminal doesn't stall

Budget 10–20 minutes, most of it MacTeX. Then open a new terminal (or
`exec zsh`) and the prompt is up.

Two switches, if you want it unattended:

```bash
DOTFILES_YES=1  ~/.dotfiles/bootstrap.sh     # ask nothing, assume yes
DOTFILES_APPS=1 ~/.dotfiles/bootstrap.sh     # also install the GUI apps
```

Skip `DOTFILES_APPS` on the first run and read `Brewfile.apps` first — it is an
inventory of the old machine's `/Applications`, not a recommendation, and it is
a large download.

The whole thing is idempotent. Re-running it on a machine that's already set up
is a no-op, so it's also the way to pick up changes later.

### 2. GUI applications

Once you've pruned `Brewfile.apps` down to what you actually want:

```bash
brew bundle --file=~/.dotfiles/Brewfile.apps
```

A handful aren't packaged as casks (Trello, FileZilla Pro, reMarkable, VMware
Horizon, kDrive, institute-managed and App Store apps) — they're listed with
sources at the bottom of that file.

### 3. macOS preferences

Opt-in, and worth skimming before you run it. Sets fast key repeat, disables
press-and-hold so vim's `hjkl` repeat, turns off smart quotes and dashes, and
tidies Finder and the Dock.

```bash
~/.dotfiles/install/macos-defaults.sh
```

Log out and back in afterwards for the keyboard settings to take effect.

### 4. SSH

The only genuinely manual part. Copy `~/.ssh/id_rsa` and `~/.ssh/ht` across
over an encrypted channel — AirDrop or a USB stick, not email — then:

```bash
chmod 600 ~/.ssh/id_rsa ~/.ssh/ht
cp ~/.dotfiles/ssh/config.example ~/.ssh/config && chmod 600 ~/.ssh/config
$EDITOR ~/.ssh/config                        # fill in the hostnames
ssh-add --apple-use-keychain ~/.ssh/id_rsa
```

If you'd rather generate a fresh key: `ssh-keygen -t ed25519`, then add the
public half to GitHub and to the HPC/VDI hosts.

Now switch this repo's remote to SSH:

```bash
git -C ~/.dotfiles remote set-url origin git@github.com:fjug/.dotfiles.git
```

### 5. GitHub CLI

```bash
gh auth login
```

### Not handled by the scripts, on purpose

- **Gurobi** — install it and drop `gurobi.lic` in place. `zsh/10-path.zsh`
  globs `/Library/gurobi*`, so there's no version number to keep updating.
- **Institute-managed software** — FortiClient, HT Self Service, VMware Horizon.
- **Terminal** — the old machine used Terminal.app with no profile in git. For
  something nicer: `brew install --cask ghostty` (or `iterm2`).

### Check it worked

```bash
exec zsh
which starship uv eza bat rg fd fzf zoxide delta lazygit
uv python list
git config --get user.email
```

### Before wiping the old machine

See [docs/NEW-MACHINE.md](docs/NEW-MACHINE.md) — the things that are
deliberately *not* in this repo and have to come across by hand (keys, licences,
unpushed work, conda environments you still need).

---

## Installing on Linux

Same entry point. `install/packages.sh` uses Homebrew if it's there, and
otherwise falls back to apt / dnf / pacman / zypper, papering over the Debian
`batcat` and `fdfind` renames.

```bash
git clone https://github.com/fjug/.dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap.sh
```

On a machine where you can't install anything at all (an HPC login node), just
`link.sh` is fine — every tool integration is guarded, so the config degrades to
a plain vcs_info prompt and zsh's built-in history search.

---

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
docs/                 old-machine checklist, conda→uv migration
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

## Keeping two machines in sync

```bash
dotfiles-sync                                        # git pull + re-link
dotfiles-update-plugins                              # pull each zsh plugin
brew update && brew upgrade
brew bundle --file=~/.dotfiles/Brewfile
uv tool upgrade --all
```

If you add a package on one machine, add it to `Brewfile` and commit — that's
what keeps the two from drifting.

## History

The pre-2026 state is tagged `pre-cleanup-2026`. It carried a large amount of
inherited configuration from a 2012-era fork — `mrconfig` with ~60 dead Java
repositories, `plugins/*.sh` full of ImageJ/LOCI/Maven aliases, a `cwd/`
bookmark system, MacPorts and Anaconda paths for a user that no longer exists.
All of that is gone. The `.vim/` tree was kept as it was, deliberately.

Interactive shell startup went from 2.2 s to 0.28 s.

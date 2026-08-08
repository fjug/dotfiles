# Setting up a new Mac

Order matters a little: packages before symlinks (so the shell config finds the
tools it expects), symlinks before the first new terminal.

## 0. Before wiping the old machine

Things that are not, and should not be, in this repo:

- [ ] `~/.ssh/` — keys (`id_rsa`, `ht`, `jugf.pem`) and `config`.
      Copy over an encrypted channel, then `chmod 600 ~/.ssh/*`.
      **Also**: the old `~/.ssh` accumulated plaintext secrets
      (`ngrok_recovery_codes.txt`, `Matrix_security-key.txt`, a Google
      `client_secret_*.json`). Move those into a password manager rather than
      copying them to the new disk.
- [ ] `~/.config/gh/hosts.yml` — or just run `gh auth login` again.
- [ ] `mas list` output, if you want the App Store apps back by ID.
- [ ] Any conda environment you still need — see [conda-to-uv.md](conda-to-uv.md).
- [ ] Licence files: Gurobi (`gurobi.lic`), Adobe, TeamViewer, iStat Menus.
- [ ] `~/GIT` and `~/git` — check for uncommitted or unpushed work:
      `for d in ~/GIT/*/; do git -C "$d" status --short --branch; done`

## 1. Bootstrap

```bash
xcode-select --install
git clone https://github.com/fjug/.dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

That installs Homebrew, the `Brewfile` baseline, symlinks every config, and
sets up uv with managed Python 3.11/3.12/3.13 plus the global tools.

Then open a new terminal (or `exec zsh`). The zsh plugins clone themselves on
first start.

## 2. GUI applications

`Brewfile.apps` mirrors what was on the old machine. Read it first — it is an
inventory, not a recommendation — then:

```bash
brew bundle --file=~/.dotfiles/Brewfile.apps
```

A handful aren't available as casks (Trello, FileZilla Pro, reMarkable, VMware
Horizon, kDrive, institute-managed apps, App Store apps). They're listed at the
bottom of that file.

## 3. macOS preferences

```bash
~/.dotfiles/install/macos-defaults.sh
```

Opt-in and worth reading first. Sets fast key repeat, disables press-and-hold
(so vim's `hjkl` repeat), turns off smart quotes, and tidies Finder/Dock.
Log out and back in afterwards for the keyboard settings.

## 4. SSH

```bash
cp ~/.dotfiles/ssh/config.example ~/.ssh/config
chmod 600 ~/.ssh/config
$EDITOR ~/.ssh/config          # fill in hostnames
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

If you're generating a fresh key rather than copying: `ssh-keygen -t ed25519`,
then add the public half to GitHub and to the HPC/VDI hosts.

## 5. Things that stay manual

- **Terminal**: the old machine used Terminal.app with no saved profile in git.
  If you want a nicer one, `brew install --cask ghostty` or `iterm2`.
- **Karabiner-Elements**: `~/.config/karabiner` existed on the old machine but
  the app itself was gone — stale config, deliberately not carried over.
- **Gurobi**: install, then drop `gurobi.lic` in place. `zsh/10-path.zsh` finds
  any `/Library/gurobi*` automatically, so no version pinning to update.
- **Adobe CC / Office / institute VPN**: sign in per app.

## Afterwards

Check the shell is healthy:

```bash
exec zsh
which starship uv eza bat rg fd fzf zoxide delta lazygit
uv python list
git config --get user.email
```

## Keeping the two machines in sync

```bash
dotfiles-sync              # git pull + re-link
dotfiles-update-plugins    # pull each zsh plugin
brew update && brew upgrade && brew bundle --file=~/.dotfiles/Brewfile
uv tool upgrade --all
```

If you add a package on one machine, add it to `Brewfile` and commit — that's
what keeps the two from drifting.

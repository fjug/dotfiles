# Brewfile — the baseline. `brew bundle --file=Brewfile`
#
# Only top-level things go here; Homebrew resolves the ~90 transitive
# dependencies (icu4c, libpng, harfbuzz, ...) on its own. Nothing is version
# pinned, so a fresh install always lands on current releases.

# --- shell ------------------------------------------------------------------
# Homebrew's zsh rather than Apple's: currently 5.9.2 against the system's 5.9,
# native arm64 instead of a universal binary, and it tracks upstream releases
# instead of waiting for a macOS point update. bootstrap.sh offers to make it
# the login shell.
brew "zsh"
brew "zsh-completions"
brew "starship"                 # prompt (replaces the oh-my-zsh bira_conda theme)

# --- modern CLI core --------------------------------------------------------
brew "eza"                      # ls
brew "bat"                      # cat
brew "ripgrep"                  # grep
brew "fd"                       # find
brew "fzf"                      # fuzzy finder: Ctrl-R, Ctrl-T, Alt-C
brew "zoxide"                   # `z` — replaces the old cwd/swd/lwd bookmarks
brew "jq"                       # JSON
brew "tree"
brew "btop"                     # system monitor
brew "tldr"                     # short man pages
brew "wget"

# --- git --------------------------------------------------------------------
brew "git"
brew "git-lfs"
brew "git-gui"
brew "git-delta"                # syntax-highlighted diffs
brew "lazygit"                  # terminal git UI
brew "gh"                       # GitHub CLI

# --- python: uv only --------------------------------------------------------
# No conda, no pyenv, no system-python installs. uv manages interpreters too,
# so there is deliberately no `brew "python"` line here.
brew "uv"

# --- other languages / runtimes ---------------------------------------------
brew "node"

# --- science / media --------------------------------------------------------
brew "hdf5"
brew "ffmpeg"
brew "pandoc"
brew "librsvg"

# --- casks ------------------------------------------------------------------
cask "meld"                     # GUI diff/merge, wired up in .gitconfig
cask "mactex"                   # LaTeX (large — comment out for a slim box)
cask "claude-code"
cask "ngrok"
cask "qlmarkdown"               # Quick Look for Markdown
cask "ttscoff-mmd-quicklook"    # Quick Look for MultiMarkdown

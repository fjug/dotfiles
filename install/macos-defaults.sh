#!/usr/bin/env bash
# macOS system preferences worth setting on a fresh machine.
#
# Opt-in: this is NOT run by bootstrap.sh automatically. Read it, then run it.
# Some settings need a logout (or the listed `killall`) to take effect.

set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES/install/lib.sh"

is_macos || die "this script is macOS only"

confirm "Apply macOS defaults?" || exit 0

# Keep sudo alive for the duration.
sudo -v

# --- keyboard ----------------------------------------------------------------
# The fast key repeat you already had configured on the old machine.
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Hold a key to repeat it rather than showing the accent picker — needed for vim.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Full keyboard access: Tab moves between all controls, not just text fields.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# --- text input --------------------------------------------------------------
# Smart quotes and dashes mangle code and terminal input.
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# --- Finder ------------------------------------------------------------------
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"      # list view
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"      # search here, not everywhere
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# No .DS_Store on network shares or USB sticks.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Dock --------------------------------------------------------------------
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false                     # don't reorder spaces
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15

# --- screenshots -------------------------------------------------------------
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# --- misc --------------------------------------------------------------------
# Save to disk by default, not iCloud.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# Expand the save and print panels by default.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
# Don't prompt about apps downloaded from the internet on every first launch.
defaults write com.apple.LaunchServices LSQuarantine -bool false

killall Finder Dock SystemUIServer 2>/dev/null || true

ok "macOS defaults applied — log out and back in for the keyboard settings"

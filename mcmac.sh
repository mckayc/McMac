#!/usr/bin/env bash
# 
# Bootstrap script for setting up a new OSX machine
# 
# Run this command in a terminal: curl -O https://raw.githubusercontent.com/mckayc/McMac/master/mcmac.sh; bash mcmac.sh 
#
# This should be idempotent so it can be run multiple times.
#
# Some apps don't have a cask and so still need to be installed by hand. These
# include:
#
#

echo "Starting bootstrapping"

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

echo "Installing OBS"
brew cask install obs

echo "Installing cask..."

CASKS=(
    darktable
    gimp
    inkscape
    blender
    tunnelblick
    obs
    ultimaker-cura
    spectacle
    virtualbox
    vlc
)

echo "Installing cask apps..."
brew cask install ${CASKS[@]}

echo "Configuring OSX..."

# Set fast key repeat rate
#defaults write NSGlobalDomain KeyRepeat -int 0

# Require password as soon as screensaver or sleep mode starts
#defaults write com.apple.screensaver askForPassword -int 1
#defaults write com.apple.screensaver askForPasswordDelay -int 0

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Enable tap-to-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Disable "natural" scroll
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

#echo "Creating folder structure..."
#[[ ! -d Wiki ]] && mkdir Wiki
#[[ ! -d Workspace ]] && mkdir Workspace

echo "Bootstrapping complete"

echo "Installing Google Fonts"
curl https://raw.githubusercontent.com/qrpike/Web-Font-Load/master/install.sh | sh\

echo "Google Fonts installation complete"

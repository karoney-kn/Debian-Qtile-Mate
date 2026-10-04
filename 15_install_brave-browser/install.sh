#!/bin/bash
# ACTION: Install Brave Browser, add DEB822 repositories, and set as default browser
# INFO: Configures official Brave Browser using the modern .sources format and replaces chromium
# DEFAULT: y

# Config variables
repo_list="/etc/apt/sources.list.d/brave-browser-release.sources"
keyring_path="/usr/share/keyrings/brave-browser-archive-keyring.gpg"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper function: aligned visual logging output
run_step() {
    local label="$1"
    shift
    
    printf "  %-50s " "${label}..."
    
    local output
    if output=$("$@" 2>&1); then
        echo -e "[ ${GREEN}OK${NC} ]"
    else
        echo -e "[${RED}FAIL${NC}]"
        [ -n "$output" ] && echo -e "${YELLOW}${output}${NC}" >&2
        return 1
    fi
}

echo -e "\e[1mConfiguring Brave Browser repository and installation...\e[0m"

# Ensure curl is installed first
if ! command -v curl &>/dev/null; then
    run_step "Installing curl dependency" sudo apt-get install -y -qq curl
fi

# Add DEB822 repository and signing key if not present
if [ ! -f "$repo_list" ]; then
    run_step "Downloading Brave GPG signing key" \
        sudo curl -fsSLo "$keyring_path" https://brave.com
    
    run_step "Configuring Brave Browser DEB822 sources" \
        sudo curl -fsSLo "$repo_list" https://brave.com
    
    run_step "Updating APT package cache" sudo apt-get update -qq
fi

# Install Brave Browser package and purge Chromium
run_step "Installing brave-browser package" sudo apt-get install -y -qq brave-browser
run_step "Removing chromium package" sudo apt-get remove -y -qq chromium

# Register and set Brave Browser as default system browser alternatives
run_step "Registering x-www-browser alternative" sudo update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/brave-browser 200
run_step "Setting x-www-browser default alternative" sudo update-alternatives --set x-www-browser /usr/bin/brave-browser

run_step "Registering gnome-www-browser alternative" sudo update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/brave-browser 200
run_step "Setting gnome-www-browser default alternative" sudo update-alternatives --set gnome-www-browser /usr/bin/brave-browser

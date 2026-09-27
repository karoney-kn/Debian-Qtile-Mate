#!/bin/bash
# ACTION: Install Google Chrome, add to repositories, and set as default browser
# INFO: Configures official Google Chrome repository with signed key keyring and replaces chromium
# DEFAULT: y

# Config variables
repo_list="/etc/apt/sources.list.d/google-chrome.list"
keyring_path="/usr/share/keyrings/googlechrome-keyring.gpg"

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

echo -e "\e[1mConfiguring Google Chrome browser repository and installation...\e[0m"

# Add repository and signing key if not present
if ! grep -R "dl.google.com/linux/chrome/deb/" /etc/apt/ &>/dev/null; then
    run_step "Downloading Google GPG signing key" bash -c "wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o '$keyring_path'"
    
    repo_entry="deb [arch=amd64 signed-by=$keyring_path] http://dl.google.com/linux/chrome/deb/ stable main"
    run_step "Configuring Google Chrome repository list" bash -c "echo '$repo_entry' | sudo tee '$repo_list' >/dev/null"
    
    run_step "Updating APT package cache" sudo apt-get update -qq
fi

# Install Google Chrome package and purge Chromium
run_step "Installing google-chrome-stable package" sudo apt-get install -y -qq google-chrome-stable
run_step "Removing chromium package" sudo apt-get remove -y -qq chromium

# Set Google Chrome as default system browser alternatives
run_step "Setting x-www-browser default alternative" sudo update-alternatives --set x-www-browser /usr/bin/google-chrome-stable
run_step "Setting gnome-www-browser default alternative" sudo update-alternatives --set gnome-www-browser /usr/bin/google-chrome-stable
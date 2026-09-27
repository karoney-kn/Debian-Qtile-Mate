#!/bin/bash
# ACTION: Install Sublime Text, add repositories and set as default editor
# INFO: Installs Sublime Text via official APT repository and updates x-text-editor alternatives
# DEFAULT: y

# Config variables
repo_list="/etc/apt/sources.list.d/sublimetext.list"
keyring_path="/usr/share/keyrings/sublimetext-keyring.gpg"

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

echo -e "\e[1mConfiguring Sublime Text repository and installation...\e[0m"

# Configure repository and GPG keyring if not present
if ! grep -R "download.sublimetext.com" /etc/apt/ &>/dev/null; then
    run_step "Downloading Sublime HQ GPG signing key" bash -c "wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --dearmor --yes -o '$keyring_path'"
    
    repo_entry="deb [arch=amd64 signed-by=$keyring_path] https://download.sublimetext.com/ apt/stable/"
    run_step "Configuring Sublime Text repository list" bash -c "echo '$repo_entry' | sudo tee '$repo_list' >/dev/null"
    
    run_step "Updating APT package cache with Sublime Text repository" sudo apt-get update -qq
fi

# Install Sublime Text
run_step "Installing sublime-text package" sudo apt-get install -y -qq sublime-text

# Configure default text editor alternatives
run_step "Registering subl in x-text-editor alternatives" sudo update-alternatives --install /usr/bin/x-text-editor x-text-editor /usr/bin/subl 90
run_step "Setting subl as default x-text-editor alternative" sudo update-alternatives --set x-text-editor /usr/bin/subl
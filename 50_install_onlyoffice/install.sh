#!/bin/bash
# ACTION: Install OnlyOffice package and add to repositories
# INFO: OnlyOffice offers a secure online office suite highly compatible with MS Office formats
# DEFAULT: n

# Config variables
repo_list="/etc/apt/sources.list.d/onlyoffice.list"
keyring_path="/usr/share/keyrings/onlyoffice-keyring.gpg"

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

echo -e "\e[1mConfiguring OnlyOffice Desktop Editors installation...\e[0m"

# Configure repository and GPG keyring if not present
if ! grep -R "onlyoffice.com" /etc/apt/ &>/dev/null; then
    run_step "Downloading OnlyOffice GPG signing key" bash -c "wget -qO- https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | sudo gpg --dearmor --yes -o '$keyring_path'"
    
    repo_entry="deb [signed-by=$keyring_path] https://download.onlyoffice.com/repo/debian squeeze main"
    run_step "Configuring OnlyOffice repository list" bash -c "echo '$repo_entry' | sudo tee '$repo_list' >/dev/null"
    
    run_step "Updating APT package cache with OnlyOffice repository" sudo apt-get update -qq
fi

# Install OnlyOffice Desktop Editors
run_step "Installing onlyoffice-desktopeditors package" sudo apt-get install -y -qq onlyoffice-desktopeditors
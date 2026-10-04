#!/bin/bash
# ACTION: Install sudo and add primary user (UID 1000) to sudo group
# INFO: Installs sudo and grants administrative privileges to the primary desktop user
# DEFAULT: y

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

echo -e "\e[1mConfiguring privilege management (sudo)...\e[0m"

# Refresh apt cache if cache is older than 24 hours or missing
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
    run_step "Updating package cache" sudo apt-get update -qq
fi

# Install sudo package
run_step "Installing sudo package" sudo apt-get install -y -qq sudo

# Identify primary user account (UID 1000)
primary_user=$(cut -f 1,3 -d: /etc/passwd | grep :1000$ | cut -f1 -d:)

# Add primary user to sudo group if found
if [ -n "$primary_user" ]; then
    run_step "Adding user ($primary_user) to sudo group" sudo usermod -aG sudo "$primary_user"
else
    echo -e "${YELLOW}Warning: No user account found with UID 1000.${NC}"
fi
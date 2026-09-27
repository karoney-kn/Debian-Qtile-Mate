#!/bin/bash
# ACTION: Install script to control screen brightness
# INFO: Installs brightness control script used for mouse wheel increments in tint2/WM bar
# DEFAULT: n

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
brightness_installer="$base_dir/brightness"

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

echo -e "\e[1mInstalling screen brightness utility...\e[0m"

# Validate installer script existence
if [ -f "$brightness_installer" ]; then
    run_step "Executing brightness installer script" sudo bash "$brightness_installer" -I
else
    echo -e "${RED}ERROR: Brightness installer script not found at $brightness_installer${NC}" >&2
    exit 1
fi
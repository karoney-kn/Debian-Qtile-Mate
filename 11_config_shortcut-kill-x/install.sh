#!/bin/bash
# ACTION: Enable CTRL+ALT+BACKSPACE shortcut to kill X server
# INFO: Configures /etc/default/keyboard to allow killing unresponsive X server sessions
# DEFAULT: y

# Config variables
keyboard_file="/etc/default/keyboard"

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

echo -e "\e[1mConfiguring X server terminate shortcut...\e[0m"

# Verify keyboard configuration file exists
if [ ! -f "$keyboard_file" ]; then
    echo -e "${YELLOW}Warning: $keyboard_file not found. Skipping keyboard options configuration.${NC}"
    exit 0
fi

# Idempotency check: Exit cleanly if shortcut is already configured
if grep -q "terminate:ctrl_alt_bksp" "$keyboard_file" 2>/dev/null; then
    run_step "Checking X server terminate shortcut status" true
    exit 0
fi

# Modify existing XKBOPTIONS variable or append new definition
if grep -q "^XKBOPTIONS=" "$keyboard_file" 2>/dev/null; then
    run_step "Appending shortcut to existing XKBOPTIONS" sudo sed -i 's/XKBOPTIONS="/XKBOPTIONS="terminate:ctrl_alt_bksp,/' "$keyboard_file"
else
    run_step "Adding XKBOPTIONS to $keyboard_file" bash -c "echo 'XKBOPTIONS=\"terminate:ctrl_alt_bksp\"' | sudo tee -a '$keyboard_file' >/dev/null"
fi
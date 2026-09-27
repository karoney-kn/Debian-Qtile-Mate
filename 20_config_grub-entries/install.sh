#!/bin/bash
# ACTION: Config GRUB to disable recovery and UEFI entries
# INFO: Removes redundant recovery and UEFI sub-menus from the GRUB interface
# DEFAULT: n

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
grub_file="/etc/default/grub"
conf_file="$base_dir/grub.conf"

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

echo -e "\e[1mConfiguring GRUB menu entries...\e[0m"

# Verify GRUB configuration source file
if [ -f "$conf_file" ]; then
    # Purge existing keys matching those in grub.conf
    for key in $(cut -f1 -d= "$conf_file" 2>/dev/null); do
        run_step "Purging $key from $grub_file" sudo sed -i "/\b$key=/Id" "$grub_file"
    done

    # Append new GRUB settings
    run_step "Appending settings to $grub_file" bash -c "cat '$conf_file' | sudo tee -a '$grub_file' >/dev/null"

    # Disable UEFI firmware entry if present
    if [ -f "/etc/grub.d/30_uefi-firmware" ]; then
        run_step "Disabling 30_uefi-firmware menu script" sudo chmod -x /etc/grub.d/30_uefi-firmware
    fi

    # Regenerate GRUB configuration
    run_step "Regenerating GRUB configuration file" sudo update-grub
else
    echo -e "${YELLOW}Warning: Configuration file $conf_file not found. Skipping GRUB updates.${NC}"
fi
#!/bin/bash
# ACTION: Config system to show text messages during boot time
# INFO: Configures GRUB boot parameters to output detailed kernel console messages instead of splash screens
# DEFAULT: y

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

echo -e "\e[1mConfiguring verbose GRUB boot parameters...\e[0m"

# Verify GRUB configuration source file existence
if [ -f "$conf_file" ]; then
    # Purge existing keys matching those defined in grub.conf
    for key in $(cut -f1 -d= "$conf_file" 2>/dev/null); do
        run_step "Purging $key from $grub_file" sudo sed -i "/\b$key=/Id" "$grub_file"
    done

    # Append boot message parameters using non-interactive sudo tee
    run_step "Applying boot display settings to $grub_file" bash -c "cat '$conf_file' | sudo tee -a '$grub_file' >/dev/null"

    # Regenerate GRUB configuration file
    run_step "Regenerating GRUB bootloader configuration" sudo update-grub
else
    echo -e "${YELLOW}Warning: Configuration file $conf_file not found. Skipping boot display setup.${NC}"
fi
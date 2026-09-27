#!/bin/bash
# ACTION: Config users home directories permissions to 0750 (for current and future users)
# INFO: Secures home directories by revoking world-read privileges (default 0755)
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"

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

echo -e "\e[1mEnforcing 0750 home directory permissions...\e[0m"

# Update default directory mode for future created users
if [ -f /etc/adduser.conf ]; then
    run_step "Updating DIR_MODE in /etc/adduser.conf" sudo sed -i 's/DIR_MODE=[0-9]*/DIR_MODE=0750/g' /etc/adduser.conf
fi

# Restrict permissions for existing standard user home directories
for d in /home/*/; do
    [ -d "$d" ] || continue
    username="$(basename "$d")"
    id "$username" &>/dev/null || continue

    run_step "Securing home directory ($username)" sudo chmod 0750 "$d"
done
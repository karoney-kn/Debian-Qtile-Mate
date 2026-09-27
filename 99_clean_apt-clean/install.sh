#!/bin/bash
# ACTION: Safe system maintenance, orphan package removal, and APT cache cleanup
# INFO: Safely removes orphaned dependencies, clears local .deb archives, and frees system disk space
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

echo -e "\e[1mExecuting system maintenance and cleanup...\e[0m"

# Refresh APT package cache
run_step "Updating APT package cache" sudo apt-get update -qq

# Purge unused orphaned dependencies
run_step "Removing orphaned dependencies and config files" sudo apt-get autoremove --purge -y -qq

# Clean obsolete and downloaded .deb archive packages
run_step "Cleaning obsolete cached packages (autoclean)" sudo apt-get autoclean -y -qq
run_step "Purging local package archive cache (clean)" sudo apt-get clean -y -qq

# Vacuum systemd journal logs to retain 3 days or 100MB
if command -v journalctl &>/dev/null; then
    run_step "Vacuuming system logs older than 3 days" sudo journalctl --vacuum-time=3d
    run_step "Limiting system logs total size to 100M" sudo journalctl --vacuum-size=100M
fi

# Display current root filesystem usage
echo -e "\n\e[1mRoot partition disk usage summary:\e[0m"
df -h / | awk 'NR==1 || NR==2 {print "  " $0}'
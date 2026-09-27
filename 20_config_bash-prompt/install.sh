#!/bin/bash
# ACTION: Config new bash prompt
# INFO: Bash prompt show colors and info about current dir and user
# DEFAULT: y


# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
comment_mark="#DEBIAN-QTILE"


# Standardizing color palette output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

run_step() {
    local label="$1"
    shift
    
    # Print the step description padded to 50 characters
    printf "  %-50s " "${label}..."
    
    # Capture combined stdout and stderr to a temp log variable
    local output
    if output=$("$@" 2>&1); then
        echo -e "[ ${GREEN}OK${NC} ]"
    else
        echo -e "[${RED}FAIL${NC}]"
        # Log error output to file and terminal if failed
        [ -n "$output" ] && echo -e "${YELLOW}${output}${NC}" >&2
        return 1
    fi
}

echo -e "\e[1mSetting configs for regular users in /home...\e[0m"

# Loop ONLY through user directories inside /home
for d in /home/*/; do
	# Skip if directory does not exist or isn't a valid system user
	[ ! -d "$d" ] && continue
	! id "$(basename "$d")" &>/dev/null && continue

	bashrc_path="${d}.bashrc"
	owner=$(stat -c %u:%g "$d" 2>/dev/null || echo "$(basename "$d"):$(basename "$d")")

	# Clean previous additions, append new prompt config, and set ownership
	run_step "Removing old prompt configurations"			sed -i "/$comment_mark/Id" "$bashrc_path" 2>/dev/null
	run_step "Appending new prompt config to .bashrc"		cat "$base_dir/bashrc" >> "$bashrc_path" && chown "$owner" "$bashrc_path"

done
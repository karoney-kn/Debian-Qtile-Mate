#!/bin/bash
# ACTION: Config modified .profile file with new path (sbin for regular users) and color definitions
# INFO: Updates .profile and .xsession for regular user home directories under /home
# DEFAULT: y
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

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"

echo -e "\e[1mSetting configs for regular users in /home...\e[0m"

# Loop ONLY through user directories inside /home
for d in /home/*/; do
	# Skip if directory does not exist or isn't a valid system user
	[ ! -d "$d" ] && continue
	! id "$(basename "$d")" &>/dev/null && continue

	owner=$(stat -c %u:%g "$d" 2>/dev/null || echo "$(basename "$d"):$(basename "$d")")

	# Copy configs and set ownership
	run_step "Copying profile file to $d/"			cp -v "$base_dir/profile" "$d/.profile" && chown "$owner" "$d/.profile"
	run_step "Copying xsession file to $d/"			cp -v "$base_dir/xsession" "$d/.xsession" && chown "$owner" "$d/.xsession"
done
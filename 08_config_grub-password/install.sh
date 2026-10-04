#!/bin/bash
# ACTION: Config GRUB with password protection to prevent users editing entries
# INFO: Secures boot entries by requiring PBKDF2 authentication to edit GRUB parameters
# DEFAULT: n

# Config variables
comment_mark="#DEBIAN-QTILE"
custom_grub="/etc/grub.d/40_custom"

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

echo -e "\e[1mConfiguring GRUB authentication security...\e[0m"

# Prompts for GRUB administrative credentials

printf "Enter GRUB username: " >&2
read -r guser

if [[ ! "$guser" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}ERROR: Invalid username format. Must match ^[a-zA-Z0-9_-]+$${NC}" >&2
    exit 1
fi

printf "Enter password for user %s: " "$guser" >&2
read -rs gpass
echo >&2

if [ -z "$gpass" ]; then
    echo -e "${RED}ERROR: Password cannot be empty.${NC}" >&2
    exit 1
fi

# Generate PBKDF2 hash from provided password
pbkdf2_pass="$(echo -e "${gpass}\n${gpass}" | grub-mkpasswd-pbkdf2 | grep "grub.pbkdf2.*" -o)"

if [ -z "$pbkdf2_pass" ]; then
    echo -e "${RED}ERROR: Failed to generate PBKDF2 password hash.${NC}" >&2
    exit 1
fi

# Purge existing custom entries matching the comment marker
run_step "Purging previous GRUB auth settings" sudo sed -i "/${comment_mark}/Id" "$custom_grub"

# Append credential blocks using privilege-safe tee
auth_block=$(cat <<EOF
set superusers="$guser"    $comment_mark
password_pbkdf2 $guser $pbkdf2_pass    $comment_mark
EOF
)

run_step "Writing superuser credentials to $custom_grub" bash -c "echo '$auth_block' | sudo tee -a '$custom_grub' >/dev/null"

# Make default menu entries unrestricted so system boots normally without password
for script_file in /etc/grub.d/*; do
    [ -f "$script_file" ] || continue
    run_step "Setting unrestricted boot for $(basename "$script_file")" bash -c "sudo sed -i 's/--unrestricted//g' '$script_file' && sudo sed -i 's/\bmenuentry\b/menuentry --unrestricted /g' '$script_file'"
done

# Regenerate GRUB configuration file
run_step "Regenerating GRUB configuration file" sudo update-grub
#!/bin/bash
# ACTION: Config Linux login in text mode (tty) with ufetch style and install physlock
# INFO: Sets boot target to multi-user, installs physlock locker, and configures tty1 autostart
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
comment_mark="#Debian-Qtile-Mate-loginfetch"

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

echo -e "\e[1mConfiguring TTY text mode login and physlock...\e[0m"

# Set default boot target to multi-user (TTY mode)
run_step "Setting systemd default target to multi-user" sudo systemctl set-default multi-user.target

# Refresh apt cache if cache is older than 24 hours or missing
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
    run_step "Updating package cache" sudo apt-get update -qq
fi

# Install physlock package
run_step "Installing physlock package" sudo apt-get install -y -qq physlock

# Configure physlock service for systemd suspend integration
if [ -f "$base_dir/physlock.service" ]; then
    run_step "Installing physlock systemd service" sudo cp "$base_dir/physlock.service" /etc/systemd/system/
    run_step "Enabling physlock systemd service" sudo systemctl enable physlock.service
fi

# Set physlock as default x-locker alternative
physlock_bin="$(which physlock 2>/dev/null || echo "/usr/bin/physlock")"
run_step "Setting physlock as default x-locker alternative" sudo update-alternatives --install /usr/bin/x-locker x-locker "$physlock_bin" 90

# Configure tty1 to autostart X session upon user login
run_step "Cleaning old tty1 autostart hooks in /etc/profile" sudo sed -i "/$comment_mark/Id" /etc/profile

autostart_hook='[ ! "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && PROMPT_COMMAND="startx && exit;" '"$comment_mark"
run_step "Configuring tty1 autostart in /etc/profile" bash -c "echo '$autostart_hook' | sudo tee -a /etc/profile >/dev/null"

# Backup issue files and install loginfetch utility
if [ -f "$base_dir/loginfetch" ]; then
    [ -f /etc/issue.net ] || run_step "Creating /etc/issue.net placeholder" sudo touch /etc/issue.net
    [ -f /etc/issue ] && run_step "Backing up /etc/issue to /etc/issue.old" sudo cp /etc/issue /etc/issue.old
    run_step "Installing loginfetch to /usr/bin/" sudo cp "$base_dir/loginfetch" /usr/bin/
    run_step "Setting execution permissions for loginfetch" sudo chmod a+x /usr/bin/loginfetch
fi

# Configure getty systemd override to display loginfetch on TTY login prompt
run_step "Creating getty systemd service drop-in directory" sudo mkdir -p /etc/systemd/system/getty@.service.d/

getty_override=$(cat <<EOF
[Service]
ExecStartPre=-/bin/bash -c "/usr/bin/loginfetch"
EOF
)

run_step "Applying getty override configuration" bash -c "echo '$getty_override' | sudo tee /etc/systemd/system/getty@.service.d/override.conf >/dev/null"
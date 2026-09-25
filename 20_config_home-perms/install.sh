#!/bin/bash
# ACTION: Config users home directories permissions to 750 (for current and future users)
# INFO: By default home directories permissions are 755 and grant read permissions to everyone
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"

# Helper function: runs command normally, falls back to sudo if permissions fail
sudo_exec() {
	if ! "$@" 2>/dev/null; then
		echo -e "\e[33mElevated privileges required for: $*\e[0m"
		sudo "$@"
	fi
}

# Config adduser for create users with $HOME permissions 0750
if [ -f /etc/adduser.conf ]; then
	sudo_exec sed -i 's/DIR_MODE=[0-9]*/DIR_MODE=0750/g' /etc/adduser.conf
fi

# Config home permissions for existing users
for d in /home/*/ ; do
	# Skip non-existent directories or invalid user homes
	[ ! -d "$d" ] && continue
	[ "$(dirname "$d")" = "/home" ] && ! id "$(basename "$d")" &>/dev/null && continue

	# Set current home permissions
	sudo_exec chmod -v 0750 "$d"
done
#!/bin/bash
# ACTION: Config new bash prompt
# INFO: Bash prompt show colors and info about current dir and user
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
comment_mark="#DEBIAN-QTILE"

# Helper function: runs command normally, falls back to sudo if permissions fail
sudo_exec() {
	if ! "$@" 2>/dev/null; then
		echo -e "\e[33mElevated privileges required for: $*\e[0m"
		sudo "$@"
	fi
}

# Helper function: handles appending text via redirected stream with root escalation
append_to_file() {
	local src="$1"
	local target="$2"

	# Try writing as regular user first
	if cat "$src" >> "$target" 2>/dev/null; then
		return 0
	fi

	# Fall back to sudo if current user lacks write permission
	echo -e "\e[33mElevated privileges required to append to: $target\e[0m"
	sudo bash -c "cat '$src' >> '$target'"
}

# Copy users config
echo -e "\e[1mSetting configs to all users...\e[0m"
for d in /home/*/ /etc/skel/ /root/; do
	# Skip non-existent directories or invalid user homes
	[ ! -d "$d" ] && continue
	[ "$(dirname "$d")" = "/home" ] && ! id "$(basename "$d")" &>/dev/null && continue

	bashrc_path="$d/.bashrc"
	owner=$(stat -c %u:%g "$d" 2>/dev/null || echo "0:0")

	# Delete previous lines added (prompts for sudo if user can't write to .bashrc)
	sudo_exec sed -i "/$comment_mark/Id" "$bashrc_path"

	# Append new prompt config
	append_to_file "$base_dir/bashrc" "$bashrc_path"

	# Fix permissions if owner differs
	sudo_exec chown "$owner" "$bashrc_path"
done
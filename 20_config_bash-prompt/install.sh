#!/bin/bash
# ACTION: Config new bash prompt
# INFO: Bash prompt show colors and info about current dir and user
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
comment_mark="#DEBIAN-QTILE"



# Copy users config
echo -e "\e[1mSetting configs to all users...\e[0m"
for d in /home/*/ /etc/skel/ /root/; do
	# Skip non-existent directories or invalid user homes
	[ ! -d "$d" ] && continue
	[ "$(dirname "$d")" = "/home" ] && ! id "$(basename "$d")" &>/dev/null && continue

	bashrc_path="$d/.bashrc"
	owner=$(stat -c %u:%g "$d" 2>/dev/null || echo "0:0")

	# Delete previous lines added (prompts for sudo if user can't write to .bashrc)
	sed -i "/$comment_mark/Id" "$bashrc_path"

	# Append new prompt config
	cat "$base_dir/bashrc" >> "$d/.bashrc"

	# Fix permissions if owner differs
	chown "$owner" "$bashrc_path"

done
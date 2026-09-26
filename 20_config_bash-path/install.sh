#!/bin/bash
# ACTION: Config modified .profile file with new path (sbin for all users) and color definitions
# INFO: Debian use a profile file which PATH has no sbin dirs for regular users
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"


# Copy users config
echo -e "\e[1mSetting configs to all users...\e[0m"
for d in /home/*/ /etc/skel/ /root/; do
	# Skip invalid directories or user accounts
	[ ! -d "$d" ] && continue
	[ "$(dirname "$d")" = "/home" ] && ! id "$(basename "$d")" &>/dev/null && continue

	owner=$(stat -c %u:%g "$d" 2>/dev/null || echo "0:0")

	# Prompts for root/sudo password ONLY if the user cannot write to target
	cp -v "$base_dir/profile" "$d/.profile" && chown "$owner" "$d/.profile"
	cp -v "$base_dir/xsession" "$d/.xsession" && chown "$owner" "$d/.xsession"
done
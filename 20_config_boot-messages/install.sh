#!/bin/bash
# ACTION: Config system for show text messages during boot time
# INFO: In boot process the system can show a stupid logo or messages about the booting process
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
grub_file="/etc/default/grub"
conf_file="$base_dir/grub.conf"

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

# Check if grub configuration file exists
if [ -f "$conf_file" ]; then
	# Delete existing lines matching keys in grub.conf
	for i in $(cut -f1 -d= "$conf_file" 2>/dev/null); do
		sudo_exec sed -i "/\b$i=/Id" "$grub_file"
	done

	# Add lines to GRUB config
	echo -e "\e[1mSetting GRUB config...\e[0m"
	append_to_file "$conf_file" "$grub_file"

	# Update grub
	echo -e "\e[1mUpdating GRUB..\e[0m"
	sudo_exec update-grub
fi
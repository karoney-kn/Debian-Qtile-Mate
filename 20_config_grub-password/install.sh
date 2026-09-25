#!/bin/bash
# ACTION: Config GRUB with password protection to prevent users editing entries
# INFO: By default everyone can edit GRUB entries during boot time and login with root privileges
# DEFAULT: n

# Config variables
comment_mark="#DEBIAN-QTILE"
custom_grub="/etc/grub.d/40_custom"

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

# Ask for username and password
echo -n "Enter GRUB username: " ; read guser
if [[ ! "$guser" =~ ^[a-zA-Z0-9_-]+$ ]]; then
	echo "Username must match ^[a-zA-Z0-9_-]+$"
	exit 1
fi

echo -n "Enter password for $guser user: " ; read -s gpass
echo
if [ -z "$gpass" ]; then
	echo "Password can't be empty"
	exit 1
fi

# Config user and password
echo -e "\e[1mSetting GRUB config...\e[0m"
pbkdf2_pass="$(echo -e "$gpass\n$gpass" | grub-mkpasswd-pbkdf2 | grep "grub.pbkdf2.*" -o)"

if [ -z "$pbkdf2_pass" ]; then
	echo "Failed to generate PBKDF2 hash"
	exit 1
fi

# Remove previous configuration entries
sudo_exec sed -i "/${comment_mark}/Id" "$custom_grub"

# Append GRUB user credentials
tmp_pass_file="$(mktemp)"
echo "set superusers=\"$guser\"    $comment_mark
password_pbkdf2 $guser $pbkdf2_pass   $comment_mark" > "$tmp_pass_file"

append_to_file "$tmp_pass_file" "$custom_grub"
rm -f "$tmp_pass_file"

# Config other menu entries to allow booting without password by default
for f in /etc/grub.d/*; do
	[ -f "$f" ] || continue
	sudo_exec sed -i 's/--unrestricted//g' "$f"
	sudo_exec sed -i 's/\bmenuentry\b/menuentry --unrestricted /g' "$f"
done

# Update GRUB configuration
echo -e "\e[1mUpdating GRUB...\e[0m"
sudo_exec update-grub
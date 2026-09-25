#!/bin/bash
# ACTION: Install OnlyOffice package and add to repositories
# INFO: OnlyOffice offers a secure online office suite highly compatible with MS Office formats
# DEFAULT: n

# Config variables
repo_list="/etc/apt/sources.list.d/onlyoffice.list"

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

# Install repositories and update
if ! grep -R "onlyoffice.com" /etc/apt/ &> /dev/null; then
	echo -e "\e[1mConfiguring repositories...\e[0m"
	
	tmp_key="$(mktemp)"
	wget -qO - "https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE" > "$tmp_key"
	sudo_exec gpg --dearmor --yes -o /usr/share/keyrings/onlyoffice-keyring.gpg "$tmp_key"
	rm -f "$tmp_key"

	tmp_repo="$(mktemp)"
	echo 'deb [signed-by=/usr/share/keyrings/onlyoffice-keyring.gpg] https://download.onlyoffice.com/repo/debian squeeze main' > "$tmp_repo"
	sudo_exec cp "$tmp_repo" "$repo_list"
	rm -f "$tmp_repo"

	sudo_exec apt-get update
fi

# Install package
echo -e "\e[1mInstalling packages...\e[0m"
sudo_exec apt-get -y install onlyoffice-desktopeditors || exit 1
#!/bin/bash
# ACTION: Install Sublime Text, add repositories and set as default editor
# INFO: Sublime Text is proprietary and cross-platform text editor, very fast and beautiful, that supports many programming and markup languages
# DEFAULT: y

# Config variables
repo_list="/etc/apt/sources.list.d/sublimetext.list"

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
if ! grep -R "download.sublimetext.com" /etc/apt/ &> /dev/null; then
	echo -e "\e[1mConfiguring repositories...\e[0m"
	
	tmp_key="$(mktemp)"
	wget -qO - "https://download.sublimetext.com/sublimehq-pub.gpg" > "$tmp_key"
	sudo_exec gpg --dearmor --yes -o /usr/share/keyrings/sublimetext-keyring.gpg "$tmp_key"
	rm -f "$tmp_key"

	tmp_repo="$(mktemp)"
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sublimetext-keyring.gpg] https://download.sublimetext.com/ apt/stable/" > "$tmp_repo"
	sudo_exec cp "$tmp_repo" "$repo_list"
	rm -f "$tmp_repo"

	sudo_exec apt-get update
fi

# Install package
echo -e "\e[1mInstalling packages...\e[0m"
sudo_exec apt-get install -y sublime-text || exit 1

# Set as default
echo -e "\e[1mSetting as default alternative...\e[0m"
sudo_exec update-alternatives --install /usr/bin/x-text-editor x-text-editor /usr/bin/subl 90 && \
sudo_exec update-alternatives --set x-text-editor /usr/bin/subl
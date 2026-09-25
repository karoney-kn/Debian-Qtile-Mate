#!/bin/bash
# ACTION: Install Google Chrome, add to repositories and set has default browser
# INFO: Google Chrome is most popular web browser
# INFO: Its recommended config official repositories for weekly updates
# DEFAULT: y

# Config variables
repo_list="/etc/apt/sources.list.d/google-chrome.list"

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
if ! grep -R "dl.google.com/linux/chrome/deb/" /etc/apt/ &> /dev/null; then
	echo -e "\e[1mConfiguring repositories...\e[0m"
	
	tmp_key="$(mktemp)"
	wget -qO - "https://dl-ssl.google.com/linux/linux_signing_key.pub" > "$tmp_key"
	sudo_exec gpg --dearmor --yes -o /usr/share/keyrings/googlechrome-keyring.gpg "$tmp_key"
	rm -f "$tmp_key"

	tmp_repo="$(mktemp)"
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > "$tmp_repo"
	sudo_exec cp "$tmp_repo" "$repo_list"
	rm -f "$tmp_repo"

	sudo_exec apt-get update
fi

# Install package
echo -e "\e[1mInstalling packages...\e[0m"
sudo_exec apt-get install -y google-chrome-stable
sudo_exec apt-get remove -y chromium

# Set as default
echo -e "\e[1mSetting as default alternative...\e[0m"
sudo_exec update-alternatives --set x-www-browser /usr/bin/google-chrome-stable
sudo_exec update-alternatives --set gnome-www-browser /usr/bin/google-chrome-stable
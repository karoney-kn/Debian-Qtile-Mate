#!/bin/bash
# ACTION: Install sudo and add user 1000 to sudo group
# INFO: SUDO allow users exec commands with root privileges without login as root
# DEFAULT: y

# Helper function: runs command normally, falls back to sudo if permissions fail
sudo_exec() {
	if ! "$@" 2>/dev/null; then
		echo -e "\e[33mElevated privileges required for: $*\e[0m"
		sudo "$@"
	fi
}

# Install packages
echo -e "\e[1mInstalling packages...\e[0m"
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
	sudo_exec apt-get update
fi

sudo_exec apt-get install -y sudo

# Add user 1000 to sudo group
echo -e "\e[1mAdding users to sudo group...\e[0m"
user=$(cut -f 1,3 -d: /etc/passwd | grep :1000$ | cut -f1 -d:)

if [ -n "$user" ]; then
	sudo_exec adduser "$user" sudo
fi
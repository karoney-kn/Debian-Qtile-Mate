#!/bin/bash
# ACTION: Config Linux login in text mode (tty) using ufetch style and install a tty locker (physlock)
# INFO: Login in tty text mode is faster, light and cool
# INFO: This script config system to login in tty and show a login screen with ufetch info
# INFO: Additionaly install a tty locker (physlock) for reautenticate users when go back from suspend or lock screen
# INFO: and config tty1 to autostart X session when user login
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
comment_mark="#Debian-Qtile-Mate-loginfetch"

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

# Config runlevel 3
sudo_exec systemctl set-default multi-user.target

# Install physlock
echo -e "\e[1mInstalling locker packages...\e[0m"
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
	sudo_exec apt-get update
fi
sudo_exec apt-get -y install physlock

# Config physlock for start after suspend
sudo_exec cp "$base_dir/physlock.service" /etc/systemd/system/
sudo_exec systemctl enable physlock.service

# Add physlock as x-locker alternative
echo -e "\e[1mSetting as default alternative...\e[0m"
physlock_bin="$(which physlock 2>/dev/null || echo "/usr/bin/physlock")"
sudo_exec update-alternatives --install /usr/bin/x-locker x-locker "$physlock_bin" 90

# Config tty1 to autoexec startx
echo -e "\e[1mSetting tty1 to autostart X...\e[0m"
sudo_exec sed -i "/$comment_mark/Id" /etc/profile

tmp_profile="$(mktemp)"
echo '[ ! "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && PROMPT_COMMAND="startx && exit;" '"$comment_mark" > "$tmp_profile"
append_to_file "$tmp_profile" /etc/profile
rm -f "$tmp_profile"

# Copy script and config files:
echo -e "\e[1mInstalling script loginfetch...\e[0m"
if [ ! -f /etc/issue.net ]; then
	sudo_exec touch /etc/issue.net
fi
sudo_exec cp -v /etc/issue /etc/issue.old
sudo_exec cp -v "$base_dir/loginfetch" /usr/bin/
sudo_exec chmod -v a+x /usr/bin/loginfetch

# Config getty to run loginfetch every time tty login is displayed:
if [ ! -d "/etc/systemd/system/getty@.service.d/" ]; then
	sudo_exec mkdir -vp "/etc/systemd/system/getty@.service.d/"
fi

tmp_override="$(mktemp)"
echo '[Service]
ExecStartPre=-/bin/bash -c "/usr/bin/loginfetch"' > "$tmp_override"
sudo_exec cp "$tmp_override" /etc/systemd/system/getty@.service.d/override.conf
rm -f "$tmp_override"
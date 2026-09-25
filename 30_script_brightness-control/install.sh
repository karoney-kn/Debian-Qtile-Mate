#!/bin/bash
# ACTION: Install script to control screen brightness
# INFO: Script brightness allow increment and decrement screen brightness
# INFO: Is used in tint2 taskbar config for inc/dec brightness with mouse wheel
# DEFAULT: n

base_dir="$(dirname "$(readlink -f "$0")")"

# Helper function: runs command normally, falls back to sudo if permissions fail
sudo_exec() {
	if ! "$@" 2>/dev/null; then
		echo -e "\e[33mElevated privileges required for: $*\e[0m"
		sudo "$@"
	fi
}

# Run the brightness installer script, escalating privileges only if needed
sudo_exec bash "$base_dir/brightness" -I
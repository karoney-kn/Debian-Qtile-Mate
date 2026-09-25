#!/bin/bash
# ACTION: Install vim editor, and apply some configs and plugins
# INFO: Install vim-gtk3, plug plugin manager, airline statusbar and hybrid-material colorsheme
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
comment_mark='"Debian-Qtile-Mate-vim'

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

# Install vim
echo -e "\e[1mInstalling packages...\e[0m"
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
	sudo_exec apt-get update
fi
sudo_exec apt-get install -y vim

# Config vim plug for global (all users)
echo -e "\e[1mInstalling vim plugins for all users in /etc/vim/ ...\e[0m"
sudo_exec mkdir -vp "/etc/vim/autoload"

# Fetch plug.vim to a temp file first as standard user
tmp_plug="$(mktemp)"
curl -fLo "$tmp_plug" https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sudo_exec cp "$tmp_plug" /etc/vim/autoload/plug.vim
rm -f "$tmp_plug"

sudo_exec mkdir -p "/etc/vim/plugged/"

echo -e "\e[1mAdding plugins to /etc/vim/rc.local ...\e[0m"
vimrc_local="/etc/vim/vimrc.local"

if [ -s "$vimrc_local" ]; then
	# Remove old comment lines
	sudo_exec sed -i "/${comment_mark}/Id" "$vimrc_local"
	
	# Combine base file and existing config safely via temporary file
	tmp_combined="$(mktemp)"
	cat "$base_dir/vimrc.local" "$vimrc_local" > "$tmp_combined"
	sudo_exec cp "$tmp_combined" "$vimrc_local"
	rm -f "$tmp_combined"
else
	sudo_exec cp -v "$base_dir/vimrc.local" /etc/vim/
fi

# Download all plugins non-interactively
sudo_exec vim +'PlugInstall --sync' +qa

# Copy users config
echo -e "\e[1mSetting configs to all users...\e[0m"
for d in /etc/skel/ /home/*/ /root/; do
	# Skip non-existent directories or invalid user homes
	[ ! -d "$d" ] && continue
	[ "$(dirname "$d")" = "/home" ] && ! id "$(basename "$d")" &>/dev/null && continue

	user_vimrc="$d/.vimrc"
	owner=$(stat -c %u:%g "$d" 2>/dev/null || echo "0:0")

	# Copy vimrc configuration and set ownership
	sudo_exec cp -v "${base_dir}/vimrc" "$user_vimrc"
	sudo_exec chown "$owner" "$user_vimrc"
done
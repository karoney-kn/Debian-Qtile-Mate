#!/bin/bash
# ACTION: Install vim editor, and apply some configs and plugins
# INFO: Installs vim, vim-plug manager, airline, hybrid-material theme, and provisions global/user configs
# DEFAULT: y

# Config variables
base_dir="$(dirname "$(readlink -f "$0")")"
comment_mark='"Debian-Qtile-Mate-vim'
vimrc_local="/etc/vim/vimrc.local"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper function: runs command directly, or via sudo if needed
sudo_exec() {
    if "$@" 2>/dev/null; then
        return 0
    else
        sudo "$@"
    fi
}

# Helper function: aligned visual logging output
run_step() {
    local label="$1"
    shift
    
    printf "  %-50s " "${label}..."
    
    local output
    if output=$("$@" 2>&1); then
        echo -e "[ ${GREEN}OK${NC} ]"
    else
        echo -e "[${RED}FAIL${NC}]"
        [ -n "$output" ] && echo -e "${YELLOW}${output}${NC}" >&2
        return 1
    fi
}

echo -e "\e[1mConfiguring Vim editor, vim-plug, and plugins...\e[0m"

# Refresh apt cache if cache is older than 24 hours or missing
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
    run_step "Updating package cache" sudo_exec apt-get update -qq
fi

# Install Vim package
run_step "Installing vim package" sudo_exec apt-get install -y -qq vim

# Setup vim-plug global environment in /etc/vim
run_step "Creating /etc/vim directory structure" sudo_exec mkdir -p /etc/vim/autoload /etc/vim/plugged

run_step "Downloading vim-plug plugin manager" bash -c "curl -fLo /tmp/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && sudo mv /tmp/plug.vim /etc/vim/autoload/plug.vim"

# Apply global configuration in /etc/vim/vimrc.local
if [ -f "$base_dir/vimrc.local" ]; then
    if [ -s "$vimrc_local" ]; then
        run_step "Purging old Vim config markers in $vimrc_local" sudo_exec sed -i "/${comment_mark}/Id" "$vimrc_local"
        run_step "Prepending new Vim config block to $vimrc_local" bash -c "cat '$base_dir/vimrc.local' '$vimrc_local' | sudo tee '$vimrc_local' >/dev/null"
    else
        run_step "Deploying global $vimrc_local configuration" sudo_exec cp "$base_dir/vimrc.local" "$vimrc_local"
    fi
fi

# Run automated headless plugin installation
run_step "Installing Vim plugins non-interactively" sudo_exec vim +'PlugInstall --sync' +qa

# Deploy user-level .vimrc to /etc/skel, /root, and existing user homes
if [ -f "$base_dir/vimrc" ]; then
    for target_dir in /etc/skel/ /home/*/ /root/; do
        [ -d "$target_dir" ] || continue
        
        # Verify home directory validity for existing users
        if [ "$(dirname "$target_dir")" = "/home" ]; then
            username="$(basename "$target_dir")"
            id "$username" &>/dev/null || continue
        fi

        target_file="${target_dir}.vimrc"
        owner=$(stat -c %u:%g "$target_dir" 2>/dev/null || echo "0:0")

        run_step "Deploying .vimrc to $target_dir" sudo_exec cp "$base_dir/vimrc" "$target_file"
        run_step "Setting ownership on $target_file" sudo_exec chown "$owner" "$target_file"
    done
fi
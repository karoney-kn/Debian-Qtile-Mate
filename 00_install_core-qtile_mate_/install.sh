#!/bin/bash
# ACTION: Install and configure Qtile-Mate window manager and Desktop
# INFO: 
# DEFAULT: y


set -e
# Check root
[ "$(id -u)" -ne 0 ] && { echo "Must run as root" 1>&2; exit 1; }

# Install packages
echo -e "\n\e[1mInstalling packages...\e[0m"
[ "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ] || apt-get update


# Command line options
ONLY_CONFIG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --only-config)
            ONLY_CONFIG=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages and external tools)"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
QTILE_CONFIG_DIR="$HOME/.config/qtile"
TEMP_DIR="/tmp/qtile_$$"
LOG_FILE="$HOME/qtile-install.log"

# Logging and cleanup
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rm -rf "$TEMP_DIR"' EXIT
mkdir -p "$TEMP_DIR"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
warn() { echo -e "${YELLOW}WARNING: $*${NC}" >&2; }
msg() { echo -e "${CYAN}$*${NC}"; }

# Fetch a butterscript into TEMP_DIR and run it.
# Runs from a file (not a pipe) so scripts can prompt the user.


# Package names target Debian 13 (trixie); newer releases (forky/sid) and Ubuntu differ
if [ "$ONLY_CONFIG" = false ]; then
    . /etc/os-release 2>/dev/null || die "Cannot read /etc/os-release to verify OS"
    case " $ID ${ID_LIKE:-} " in
        *" ubuntu "*) die "Unsupported OS: ${PRETTY_NAME:-unknown}. Ubuntu-based systems are not supported." ;;
    esac
    DEBIAN_BASE=$(cat /etc/debian_version 2>/dev/null || true)
    case "$DEBIAN_BASE" in
        13|13.*) ;;
        *) die "Unsupported OS: ${PRETTY_NAME:-unknown}. This installer requires a Debian 13 (trixie) base (found: ${DEBIAN_BASE:-no /etc/debian_version})." ;;
    esac
fi



read -rp "Install Qtile And Mate Desktop? (y/n) " REPLY
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

PACKAGES=(
    # core
    xorg xorg-dev xbacklight xbindkeys xvkbd xinput
    build-essential xdotool dbus-x11
    libnotify-bin libnotify-dev
    xserver-xorg xserver-xorg-core xserver-xorg-input-libinput xinit xauth
    x11-common x11-utils x11-xserver-utils x11-xkb-utils xkb-data xterm
    dbus dbus-user-session polkitd
    xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gtk xdg-dbus-proxy
    shared-mime-info desktop-file-utils s-tui dfc htop hwinfo
    lxappearance compton upower arandr gsimplecal xcape file-roller xautomation yad inxi
    libcanberra-gtk3-0 gtk-update-icon-cache gsettings-desktop-schemas
    network-manager network-manager-applet wpasupplicant wireless-regdb

    # wm
    qtile
    python3-psutil  # Required for CPU and memory monitoring in qtile bar

    # ui
    picom rofi
    dunst feh nwg-look xsettingsd network-manager-gnome lxpolkit

    # file manager
    
    gvfs-backends gvfs-fuse dialog mtools smbclient cifs-utils ripgrep fd-find unzip

    # audio
    pavucontrol pulsemixer pamixer pipewire-audio

    # utilities
    avahi-daemon acpi acpid power-profiles-daemon
    qimgv xdg-user-dirs-gtk gsimplecal

    # terminal tools
    suckless-tools eza firefox-esr

    # build deps
    cmake meson ninja-build curl pkg-config wget

    #Fonts
    fonts-freefont-ttf 

    ranger nnn lf sxiv qimgv inkscape kitty gedit l3afpad mousepad micro 
    mpv vlc audacity obs-studio ncmpcpp mkvtoolnix-gui 
    gparted gnome-disk-utility numlockx galculator cpu-x dnsutils whois curl tree btop htop bat brightnessctl

)



if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo apt-get update && sudo apt-get upgrade -y

    msg "Installing packages..."
    sudo apt-get install -y "${PACKAGES[@]}" || die "Package installation failed"

    # Enable services
    sudo systemctl disable NetworkManager-wait-online.service
else
    msg "Skipping package installation (--only-config mode)"
fi

# Installing graphics drivers
echo -e "\n\e[1mInstalling graphics drivers...\e[0m"
if systemd-detect-virt -q; then
    virt=$(systemd-detect-virt)
    case "$virt" in
        oracle)     gpu_pkgs=""                          ;;
        vmware)     gpu_pkgs="xserver-xorg-video-vmware" ;;
        qemu|kvm)   gpu_pkgs="xserver-xorg-video-qxl"    ;;
        *)          gpu_pkgs="xserver-xorg-video-fbdev"  ;;
    esac
else
    gpu="$(lspci -nn | grep -Ei 'vga|3d|display')"
    if echo "$gpu" | grep -qi intel; then
        gpu_pkgs="xserver-xorg-video-intel firmware-intel-graphics"
    elif echo "$gpu" | grep -Eqi "amd|radeon"; then
        gpu_pkgs="xserver-xorg-video-amdgpu firmware-amd-graphics"
    elif echo "$gpu" | grep -qi nvidia; then
        dpkg -l | grep -q '^ii  nvidia-driver'
        [ $? -eq 0 ] && gpu_pkgs="nvidia-driver firmware-misc-nonfree" || gpu_pkgs="xserver-xorg-video-nouveau firmware-misc-nonfree"            
    else
        gpu_pkgs="xserver-xorg-video-fbdev"
    fi
fi
apt-get install -y $gpu_pkgs


# Setup directories
xdg-user-dirs-update
mkdir -p ~/Screenshots

# Drop quickstart cheatsheet in $HOME (user can delete once read)
if [ -f "$SCRIPT_DIR/QUICKSTART.md" ]; then
    cp "$SCRIPT_DIR/QUICKSTART.md" "$HOME/QUICKSTART-qtile.md"
fi

# Handle existing config
if [ -d "$QTILE_CONFIG_DIR" ]; then
    read -rp "Found existing qtile config. Backup? (y/n) " REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$QTILE_CONFIG_DIR" "$QTILE_CONFIG_DIR.bak.$(date +%s)"
        msg "Backed up existing config"
    else
        read -rp "Overwrite without backup? (y/n) " REPLY
        [[ $REPLY =~ ^[Yy]$ ]] || die "Installation cancelled"
        rm -rf "$QTILE_CONFIG_DIR"
    fi
fi

# Copy configs
msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"

# Copy qtile configuration directory
if [ -d "$SCRIPT_DIR/qtile" ]; then
    cp -r "$SCRIPT_DIR/qtile" "$CONFIG_DIR/" || die "Failed to copy qtile configuration"
else
    die "qtile directory not found"
fi

# Make scripts executable
if [ -d "$QTILE_CONFIG_DIR/scripts" ]; then
    chmod +x "$QTILE_CONFIG_DIR/scripts/"* 2>/dev/null || true
fi


# Ensure ~/.local/bin is on PATH for display-manager logins.
# DM sessions source ~/.xsessionrc but never ~/.profile, so user-built tools
# in ~/.local/bin would otherwise be unfindable when launched from the WM.
if ! grep -qs '.local/bin' "$HOME/.xsessionrc" 2>/dev/null; then
    msg "Ensuring ~/.local/bin is on PATH via ~/.xsessionrc..."
    cat >> "$HOME/.xsessionrc" <<'XSESSIONRC_EOF'

#  ensure ~/.local/bin is on PATH
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac
XSESSIONRC_EOF
fi


echo -e "\n\e[1mCopying themes and tools...\e[0m"
# Copy theme

tar -xzvf "$SCRIPT_DIR"/iconsrami/rami.tar.gz -C /usr/share/icons/
tar -xzvf "$SCRIPT_DIR"/iconsrami/rami-grey.tar.gz -C /usr/share/icons/


# Copy welcome
cp -v ${SCRIPT_DIR}/qtilemateconfs/qtile-mate-session /usr/local/bin/
chmod a+x /usr/local/bin/qtile-mate-session
cp -v ${SCRIPT_DIR}/qtilemateconfs/settings.ini ~/.config/gtk-3.0/settings.ini 
cp -v ${SCRIPT_DIR}/qtilemateconfs/qtile-mate.desktop /usr/share/xsessions/


# Set as default
echo -e "\n\e[1mSetting as default alternative...\e[0m"
update-alternatives --set x-session-manager /usr/local/bin/qtile-mate-session

# Done
echo -e "\n${GREEN}Installation complete!${NC}"
echo "1. Log out to boot into your Qtile-Mate desktop"
echo "2. Press Super + / for keybindings"
echo "3. Super + Return for terminal, Super + Space for rofi"
echo "4. See ~/QUICKSTART-qtile.md for a quick reference"


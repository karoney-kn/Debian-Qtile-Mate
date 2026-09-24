#!/bin/bash
# ACTION: Install and configure Qtile-Mate window manager and Desktop
# INFO: Installs Qtile and MATE dependencies, copies configurations, and configures default x-session-manager
# DEFAULT: y

set -e

# Define paths and log settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
QTILE_CONFIG_DIR="$HOME/.config/qtile"
TEMP_DIR="/tmp/qtile_$$"
LOG_FILE="$HOME/qtile-install.log"

# Setup logging and execution traps
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rm -rf "$TEMP_DIR"' EXIT
mkdir -p "$TEMP_DIR"

# Standardizing color palette output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
warn() { echo -e "${YELLOW}WARNING: $*${NC}" >&2; }
msg() { echo -e "${CYAN}$*${NC}"; }

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

# OS Verification for Debian 13 (Trixie)
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
    # Core system tools & X11
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

    # Window Manager
    qtile
    python3-psutil

    # UI Components
    picom rofi
    dunst feh nwg-look xsettingsd network-manager-gnome lxpolkit

    # File Managers & Filesystems
    gvfs-backends gvfs-fuse dialog mtools smbclient cifs-utils ripgrep fd-find unzip

    # Audio Stack
    pavucontrol pulsemixer pamixer pipewire-audio

    # Power & System Utilities
    avahi-daemon acpi acpid power-profiles-daemon
    qimgv xdg-user-dirs-gtk gsimplecal

    # Terminal Applications & Fonts
    suckless-tools eza firefox-esr fonts-freefont-ttf

    # Build tools
    cmake meson ninja-build curl pkg-config wget

    # User Applications & Media
    ranger nnn lf sxiv qimgv inkscape kitty gedit l3afpad mousepad micro 
    mpv vlc audacity obs-studio ncmpcpp mkvtoolnix-gui 
    gparted gnome-disk-utility numlockx galculator cpu-x dnsutils whois tree btop bat brightnessctl
)

if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating package cache..."
    sudo apt-get update && sudo apt-get upgrade -y

    msg "Installing package array..."
    sudo apt-get install -y "${PACKAGES[@]}" || die "Package installation failed"

    # Disable latency-inducing background services
    sudo systemctl disable NetworkManager-wait-online.service
else
    msg "Skipping package installation (--only-config mode activated)"
fi

# Initialize standard XDG directories
xdg-user-dirs-update
mkdir -p "$HOME/Screenshots"

# Copy regional cheatsheet reference
if [ -f "$SCRIPT_DIR/QUICKSTART.md" ]; then
    cp "$SCRIPT_DIR/QUICKSTART.md" "$HOME/QUICKSTART-qtile.md"
fi

# Manage existing active Qtile configurations
if [ -d "$QTILE_CONFIG_DIR" ]; then
    read -rp "Found existing Qtile config. Backup current state? (y/n) " REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$QTILE_CONFIG_DIR" "$QTILE_CONFIG_DIR.bak.$(date +%s)"
        msg "Backed up existing configuration."
    else
        read -rp "Overwrite without backup? (y/n) " REPLY
        [[ $REPLY =~ ^[Yy]$ ]] || die "Installation process cancelled."
        rm -rf "$QTILE_CONFIG_DIR"
    fi
fi

# Deploy dotfiles
msg "Deploying configuration directories..."
mkdir -p "$CONFIG_DIR"

if [ -d "$SCRIPT_DIR/qtile" ]; then
    cp -r "$SCRIPT_DIR/qtile" "$CONFIG_DIR/" || die "Failed to copy Qtile configuration"
else
    die "Source 'qtile' directory not found in execution path."
fi

# Set executable execution masks on user scripts
if [ -d "$QTILE_CONFIG_DIR/scripts" ]; then
    chmod +x "$QTILE_CONFIG_DIR/scripts/"* 2>/dev/null || true
fi

# PATH initialization injection
if ! grep -qs '.local/bin' "$HOME/.xsessionrc" 2>/dev/null; then
    msg "Injecting ~/.local/bin to default PATH in ~/.xsessionrc..."
    cat >> "$HOME/.xsessionrc" <<'XSESSIONRC_EOF'

# Ensure ~/.local/bin is present in PATH for DM session environments
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac
XSESSIONRC_EOF
fi

echo -e "\n\e[1mExtracting icon packages and root assets...\e[0m"

# Extract system icons with root privileges
if [ -d "$SCRIPT_DIR/iconsrami" ]; then
    sudo tar -xzvf "$SCRIPT_DIR/iconsrami/rami.tar.gz" -C /usr/share/icons/
    sudo tar -xzvf "$SCRIPT_DIR/iconsrami/rami-grey.tar.gz" -C /usr/share/icons/
fi

# Deploy global session launchers
if [ -d "$SCRIPT_DIR/qtilemateconfs" ]; then
    sudo cp -v "${SCRIPT_DIR}/qtilemateconfs/qtile-mate-session" /usr/local/bin/
    sudo chmod a+x /usr/local/bin/qtile-mate-session
    
    mkdir -p "$HOME/.config/gtk-3.0"
    cp -v "${SCRIPT_DIR}/qtilemateconfs/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    
    sudo cp -v "${SCRIPT_DIR}/qtilemateconfs/qtile-mate.desktop" /usr/share/xsessions/
fi

# Configure session alternatives
echo -e "\n\e[1mSetting qtile-mate-session as system x-session-manager default...\e[0m"
sudo update-alternatives --install /usr/bin/x-session-manager x-session-manager /usr/local/bin/qtile-mate-session 60
sudo update-alternatives --set x-session-manager /usr/local/bin/qtile-mate-session

echo -e "\n${GREEN}Installation complete!${NC}"
echo "1. Log out to boot into your Qtile-Mate desktop"
echo "2. Press Super + / for keybindings"
echo "3. Super + Return for terminal, Super + Space for rofi"
echo "4. See ~/QUICKSTART-qtile.md for a quick reference"
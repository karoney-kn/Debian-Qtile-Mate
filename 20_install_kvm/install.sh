#!/bin/bash
# ACTION: Install complete KVM/QEMU stack, libvirt utilities, virt-manager, and virt-install/virt-iso tools
# INFO: Sets up full hardware virtualization, bridges, guest tools, and image manipulation scripts
# DEFAULT: y

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


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

echo -e "\e[1mConfiguring KVM hypervisor and virtualization stack...\e[0m"

# Refresh apt cache if older than 24 hours or missing
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
    run_step "Updating package cache" sudo apt-get update -qq
fi

# Define comprehensive KVM & Virt Tools package list
KVM_PACKAGES=(
    qemu-system-x86
    qemu-utils
    qemu-system-gui
    qemu-block-extra
    libvirt-daemon-system
    libvirt-clients
    libvirt-daemon-config-network
    virt-manager
    virt-viewer
    virtinst
    libguestfs-tools
    guestfs-tools
    genisoimage
    p7zip-full
    bridge-utils
    dnsmasq-base
    iptables
    ebtables
    vde2
    ovmf
)

# Install full KVM virtualisation suite
run_step "Installing KVM virtualization stack" sudo apt-get install -y -qq "${KVM_PACKAGES[@]}"

# Configure user group memberships for libvirt and kvm access
CURRENT_USER="${SUDO_USER:-$USER}"

if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    for group in libvirt libvirt-qemu kvm; do
        if getent group "$group" >/dev/null; then
            run_step "Adding '$CURRENT_USER' to group '$group'" sudo usermod -aG "$group" "$CURRENT_USER"
        fi
    done
fi

# Enable and start hypervisor service
run_step "Enabling and starting libvirtd service" sudo systemctl enable --now libvirtd

# Configure default NAT bridge network autostart and activation
if sudo virsh net-info default &>/dev/null; then
    run_step "Setting default virsh network to autostart" sudo virsh net-autostart default
    run_step "Starting default virsh network" sudo virsh net-start default
fi
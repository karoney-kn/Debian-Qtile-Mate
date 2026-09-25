#!/bin/bash
# ACTION: Install complete KVM/QEMU stack, libvirt utilities, virt-manager, and virt-install/virt-iso tools
# INFO: Sets up full hardware virtualization, bridges, guest tools, and image manipulation scripts
# DEFAULT: y

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

# 1. Package Cache Refresh
echo -e "\e[1mUpdating package cache...\e[0m"
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
	sudo_exec apt-get update
fi

# 2. Comprehensive KVM & Virt Tools Array
KVM_PACKAGES=(
	# Core Hypervisor & Emulation
	qemu-system-x86
	qemu-utils
	qemu-system-gui
	qemu-block-extra

	# Libvirt Daemon & Client Infrastructure
	libvirt-daemon-system
	libvirt-clients
	libvirt-daemon-config-network

	# Management Tools & GUI
	virt-manager
	virt-viewer
	virtinst                   # Provides virt-install and virt-clone

	# Guest Image & ISO Manipulation Utilities
	libguestfs-tools           # Provides virt-customize, virt-builder, virt-sysprep
	guestfs-tools              # Advanced guest inspection tools
	genisoimage                # Utility for generating bootable ISOs for unattended installs
	p7zip-full                 # Extraction tool for raw image manipulation

	# Networking & Storage Helpers
	bridge-utils
	dnsmasq-base
	iptables
	ebtables
	vde2
	ovmf                       # UEFI firmware support for virtual machines
)

echo -e "\e[1mInstalling complete KVM hypervisor and virtualization tooling...\e[0m"
sudo_exec apt-get install -y "${KVM_PACKAGES[@]}" || exit 1

# 3. User Group Permissions Assignment
CURRENT_USER="${SUDO_USER:-$USER}"

if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
	echo -e "\e[1mConfiguring user '$CURRENT_USER' access to hypervisor sockets...\e[0m"
	
	for group in libvirt libvirt-qemu kvm; do
		if getent group "$group" >/dev/null; then
			sudo_exec usermod -aG "$group" "$CURRENT_USER"
		fi
	done
fi

# 4. Service Initialization & Default Network Enablement
echo -e "\e[1mEnabling hypervisor services and NAT networking...\e[0m"
sudo_exec systemctl enable --now libvirtd

# Autostart the default NAT bridge network if defined
if sudo_exec virsh net-info default &>/dev/null; then
	sudo_exec virsh net-autostart default 2>/dev/null || true
	sudo_exec virsh net-start default 2>/dev/null || true
fi

echo -e "\e[32mKVM and virtualization tools successfully installed! Log out and back in to apply group memberships.\e[0m"
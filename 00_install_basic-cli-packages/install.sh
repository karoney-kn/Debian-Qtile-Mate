#!/bin/bash
# ACTION: Install some basic CLI packages
# INFO: Debian netinstall comes with few list of CLI installed packages
# INFO: Some basic packages are: vim zip unzip mtp-tools mailutils traceroute acl gnupg2 plocate apt-transport-https curl ntfs-3g
# DEFAULT: y

# Install free packages
echo -e "\e[1mInstalling packages...\e[0m"
[ "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ] || apt-get update  

sudo apt-get install -y base-files mount procps udev base-passwd bash coreutils dpkg apt systemd systemd-sysv util-linux login passwd tzdata locales tzdata ca-certificates usb.ids
sudo apt-get install -y vim less zip unzip p7zip-full mtp-tools mailutils traceroute acl gnupg2 plocate apt-transport-https curl wget ntfs-3g file p11-kit p11-kit-modules


#!/bin/bash
# ACTION: Install some basic GUI packages
# INFO: Debian netinstall comes with few list of GUI installed packages
# INFO: Some basic packages are: vlc gmtp mtp-tools synaptic galternatives evince firmware-linux-nonfree
# DEFAULT: y

# Check root


# Install free packages
echo -e "\e[1mInstalling packages...\e[0m"
[ "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ] || apt-get update  

sudo apt-get install -y firmware-linux-nonfree

sudo apt-get install -y \
  ranger nnn lf \
  sxiv qimgv inkscape \
  kitty gmtp synaptic galternatives atril xdotool imagemagick \
  gedit l3afpad mousepad micro \
  mpv vlc audacity obs-studio ncmpcpp mkvtoolnix-gui \
  gparted gnome-disk-utility nitrogen numlockx galculator cpu-x dnsutils whois curl tree btop htop bat brightnessctl

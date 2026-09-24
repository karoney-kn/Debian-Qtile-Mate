#!/bin/bash
# ACTION: Debian core Repositories
# INFO: Updates Official Debian repositories 
# DEFAULT: y

# Define the target path for the new repository configuration

TARGET_FILE="/etc/apt/sources.list"
# Define the exact text block to write
read -r -d '' REPO_DATA << 'EOF'
#Qtile Mate Debian Sources
#-----------------------------
#Start 

#deb cdrom:[Debian GNU/Linux 13.6.0 _Trixie_ - Official amd64 NETINST with firmware 20260711-09:42]/ trixie contrib main non-free-firmware

deb http://deb.debian.org/debian/ trixie main non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main non-free-firmware

deb http://security.debian.org/debian-security trixie-security main non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main non-free-firmware

# trixie-updates, to get updates before a point release is made;
# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports

deb http://deb.debian.org/debian/ trixie-updates main non-free-firmware
deb-src http://deb.debian.org/debian/ trixie-updates main non-free-firmware

# This system was installed using removable media other than
# CD/DVD/BD (e.g. USB stick, SD card, ISO image file).
# The matching "deb cdrom" entries were disabled at the end
# of the installation process.
# For information about how to configure apt package sources,
# see the sources.list(5) manual.

#End
EOF

echo "This script requires root privileges to modify APT sources."

# Trigger the sudo password prompt, then safely pipe the text to a root-owned file
if echo "$REPO_DATA" | sudo tee "$TARGET_FILE" > /dev/null; then
    echo "✅ Successfully added Trixie repositories to $TARGET_FILE"
    
    echo "🔄 Updating package lists..."
    sudo apt update
else
    echo "❌ Error: Failed to write the configuration. Please check your password or permissions."
    exit 1
fi

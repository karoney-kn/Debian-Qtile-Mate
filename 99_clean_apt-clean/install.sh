#!/bin/bash
# ACTION: Safe system maintenance, orphan package removal, and APT cache cleanup
# INFO: Safely removes orphaned dependencies, clears local .deb archives, and frees system disk space
# DEFAULT: y

# Helper function: runs command normally, falls back to sudo if permissions fail
sudo_exec() {
    if ! "$@" 2>/dev/null; then
        echo -e "\e[33mElevated privileges required for: $*\e[0m"
        sudo "$@"
    fi
}

# 1. Update APT Package Lists
echo -e "\e[1mRefreshing package lists...\e[0m"
sudo_exec apt-get update

# 2. Remove Orphaned & Automatically Installed Dependencies
# Note: APT tracks packages that were installed as dependencies and are no longer needed by any installed package.
echo -e "\n\e[1mRemoving unused orphaned dependencies...\e[0m"
sudo_exec apt-get -y autoremove --purge

# 3. Clean APT Cache Files
# 'autoclean' removes .deb packages that can no longer be downloaded (obsolete versions).
# 'clean' clears out the local repository of retrieved package files (.deb) in /var/cache/apt/archives.
echo -e "\n\e[1mCleaning package cache files (.deb archives)...\e[0m"
sudo_exec apt-get -y autoclean
sudo_exec apt-get -y clean

# 4. Clean Systemd Journal Logs (Retain last 3 days / max 100MB)
if command -v journalctl &>/dev/null; then
    echo -e "\n\e[1mVacuuming old system logs...\e[0m"
    sudo_exec journalctl --vacuum-time=3d 2>/dev/null || true
    sudo_exec journalctl --vacuum-size=100M 2>/dev/null || true
fi

# 5. Report Disk Usage Status
echo -e "\n\e[32mMaintenance complete! Current root partition usage:\e[0m"
df -h /
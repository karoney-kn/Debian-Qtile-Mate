#!/bin/bash
# ACTION: Install Docker Engine, Docker CLI, Containerd, and Docker Compose from official repository
# INFO: Configures official Docker GPG key, repository, installs package stack, and sets up user permissions
# DEFAULT: y

# Config variables
docker_repo_list="/etc/apt/sources.list.d/docker.list"
docker_keyring="/usr/share/keyrings/docker-archive-keyring.gpg"

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

# 1. Install prerequisites for repository setup
echo -e "\e[1mInstalling repository prerequisites...\e[0m"
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
	sudo_exec apt-get update
fi
sudo_exec apt-get install -y ca-certificates curl gnupg lsb-release

# 2. Configure Official Docker Repository
if ! grep -R "download.docker.com" /etc/apt/ &> /dev/null; then
	echo -e "\e[1mConfiguring Docker official repository...\e[0m"
	
	# Fetch GPG key to a temp file first as standard user
	tmp_key="$(mktemp)"
	curl -fsSL "https://download.docker.com/linux/debian/gpg" -o "$tmp_key"
	sudo_exec gpg --dearmor --yes -o "$docker_keyring" "$tmp_key"
	rm -f "$tmp_key"

	# Create repository source entry
	arch="$(dpkg --print-architecture)"
	tmp_repo="$(mktemp)"
	echo "deb [arch=$arch signed-by=$docker_keyring] https://download.docker.com/linux/debian trixie stable" > "$tmp_repo"
	sudo_exec cp "$tmp_repo" "$docker_repo_list"
	rm -f "$tmp_repo"

	sudo_exec apt-get update
fi

# 3. Install Docker Engine and Plugin Suite
DOCKER_PACKAGES=(
	docker-ce
	docker-ce-cli
	containerd.io
	docker-buildx-plugin
	docker-compose-plugin
)

echo -e "\e[1mInstalling Docker suite...\e[0m"
sudo_exec apt-get install -y "${DOCKER_PACKAGES[@]}" || exit 1

# 4. Configure User Group Membership
CURRENT_USER="${SUDO_USER:-$USER}"

if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
	echo -e "\e[1mAdding user '$CURRENT_USER' to docker group...\e[0m"
	if getent group docker >/dev/null; then
		sudo_exec usermod -aG docker "$CURRENT_USER"
	fi
fi

# 5. Enable and Start System Service
echo -e "\e[1mEnabling Docker daemon service...\e[0m"
sudo_exec systemctl enable --now docker.service
sudo_exec systemctl enable --now containerd.service

echo -e "\e[32mDocker installation complete! Log out and back in for group changes to take effect.\e[0m"
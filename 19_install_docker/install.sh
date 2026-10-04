#!/bin/bash
# ACTION: Install Docker Engine, Docker CLI, Containerd, and Docker Compose from official repository
# INFO: Configures official Docker repository, installs engine suite, and sets user group permissions
# DEFAULT: y

# Config variables
docker_repo_list="/etc/apt/sources.list.d/docker.list"
docker_keyring="/usr/share/keyrings/docker-archive-keyring.gpg"

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

echo -e "\e[1mConfiguring Docker Engine deployment...\e[0m"

# Refresh apt cache if older than 24 hours or missing
if [ -z "$(find /var/cache/apt/pkgcache.bin -mtime 0 2>/dev/null)" ]; then
    run_step "Updating package cache" sudo apt-get update -qq
fi

# Install repository setup dependencies
run_step "Installing repository dependencies" sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release

# Configure official Docker repository and keyring
if ! grep -R "download.docker.com" /etc/apt/ &>/dev/null; then
    run_step "Downloading Docker GPG signing key" bash -c "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor --yes -o '$docker_keyring'"
    
    # Retrieve system architecture and Debian version codename
    arch="$(dpkg --print-architecture)"
    [ -f /etc/os-release ] && . /etc/os-release
    codename="${VERSION_CODENAME:-trixie}"
    
    repo_entry="deb [arch=$arch signed-by=$docker_keyring] https://download.docker.com/linux/debian $codename stable"
    run_step "Configuring Docker repository list" bash -c "echo '$repo_entry' | sudo tee '$docker_repo_list' >/dev/null"
    
    run_step "Updating APT package cache with Docker repository" sudo apt-get update -qq
fi

# Install Docker Engine plugin suite
DOCKER_PACKAGES=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

run_step "Installing Docker Engine package suite" sudo apt-get install -y -qq "${DOCKER_PACKAGES[@]}"

# Configure user permissions for rootless docker execution
CURRENT_USER="${SUDO_USER:-$USER}"

if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    if getent group docker >/dev/null; then
        run_step "Adding user '$CURRENT_USER' to docker group" sudo usermod -aG docker "$CURRENT_USER"
    fi
fi

# Enable and start Docker system daemon services
run_step "Enabling and starting Docker service" sudo systemctl enable --now docker.service
run_step "Enabling and starting Containerd service" sudo systemctl enable --now containerd.service
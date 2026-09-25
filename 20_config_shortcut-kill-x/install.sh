#!/bin/bash
# ACTION: Enable CTRL+ALT+BACKSPACE shortcut for kill X server
# INFO: In most systems CTRL+ALT+BACKSPACE shortcut for kill X server is disabled, but is very useful for go back to login when X is not responding
# DEFAULT: y

# Config variables
keyboard_file="/etc/default/keyboard"

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

# Check if config is already set
if grep -q "terminate:ctrl_alt_bksp" "$keyboard_file" 2>/dev/null; then
  exit 0
fi

echo -e "\e[1mSetting $keyboard_file config...\e[0m"

# Modify or append the keyboard configuration
if grep -q "XKBOPTIONS" "$keyboard_file" 2>/dev/null; then
  sudo_exec sed -i 's/XKBOPTIONS="/XKBOPTIONS="terminate:ctrl_alt_bksp,/' "$keyboard_file"
else
  # Create a temporary file to use with append_to_file
  tmp_file="$(mktemp)"
  echo 'XKBOPTIONS="terminate:ctrl_alt_bksp"' > "$tmp_file"
  
  append_to_file "$tmp_file" "$keyboard_file"
  rm -f "$tmp_file"
fi
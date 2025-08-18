#!/bin/bash
# Restricted SSH shell with global + contextual blocklist

# === Global always-blocked commands (regex patterns) ===
GLOBAL_BLOCKED_COMMANDS=(
  '^podman container inspect'
  '^podman network inspect'
  '^podman volume inspect'
  '^podman secret inspect'
  '^podman image inspect'
  '^podman system info'
  '^podman mount'
  '^podman exec'
  '^podman cp'

  '^iptables'
  '^tcpdump'
  '^rsync'
  '^nmap'
  '^curl'
  '^wget'
  '^scp'
  '^ssh'

  '^killall'
  '^strace'
  '^pkill'
  '^htop'
  '^free'
  '^lsof'
  '^kill'
  '^top'
  '^gdb'
  '^ps'
  '^df'

  '^modprobe'
  '^swapoff'
  '^umount'
  '^swapon'
  '^insmod'
  '^rmmod'
  '^mount'

  '^shutdown'
  '^loginctl'
  '^poweroff'
  '^reboot'
  '^halt'

  '^apt-get'
  '^snap'
  '^apt'

  '^python3'
  '^python'
  '^py'

  '^bash'
  '^zsh'
  '^awk'
  '^sh'

  '^su'
)

# === Commands blocked outside home dir ===
CONTEXT_BLOCKED_COMMANDS=(ls cd cat nano vim less more tail)

HOME_DIR="/home/$(whoami)"
CMD="$SSH_ORIGINAL_COMMAND"

# --- Utility: check if user is inside home ---
in_home_dir() {
  [[ "$(realpath "$PWD")" == "$HOME_DIR"* ]]
}

# --- Utility: block global commands ---
block_global() {
  local cmd="$1"
  for pattern in "${GLOBAL_BLOCKED_COMMANDS[@]}"; do
    if [[ "$cmd" =~ $pattern ]]; then
      echo "❌ Command '$cmd' is globally blocked."
      return 1
    fi
  done
  return 0
}

# --- Utility: block contextual commands outside home ---
block_context() {
  local cmd="$1"
  if ! in_home_dir; then
    for forbidden in "${CONTEXT_BLOCKED_COMMANDS[@]}"; do
      if [[ "$cmd" == $forbidden* ]]; then
        echo "❌ Command '$cmd' is blocked outside $HOME_DIR"
        return 1
      fi
    done
  fi
  return 0
}

# --- Handle SSH command execution (ssh user@host "cmd") ---
if [[ -n "$CMD" ]]; then
  block_global "$CMD" || exit 1
  block_context "$CMD" || exit 1
  exec $CMD
fi

# --- Interactive shell mode (ssh user@host) ---
echo "Welcome back $USER"
echo -e "\nRunning Containers:"
podman ps

while true; do
  # Prompt
  read -p "> " CMD || exit 0
  CMD=$(echo "$CMD" | xargs)  # trim spaces
  [[ -z "$CMD" ]] && continue

  # Apply restrictions
  if block_global "$CMD" && block_context "$CMD"; then
    eval "$CMD"
  fi
done

#!/bin/bash

# Restricted SSH shell with keyboard navigation
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CMD="$SSH_ORIGINAL_COMMAND"
HOME_DIR="/home/$(whoami)"

case ":$PATH:" in
  *":$SCRIPT_DIR:"*) ;; # already in PATH, do nothing
  *) export PATH="$SCRIPT_DIR:$PATH" ;;
esac

shopt -u cdable_vars
shopt -u sourcepath
shopt -u dotglob
shopt -u extglob
complete -r
set -r

# --- Utility: safely print messages without exposing SCRIPT_DIR ---
safe_echo() {
  local msg="$*"
  echo "${msg//$SCRIPT_DIR/...}"
}

# --- Global and contextual blocked commands ---
GLOBAL_BLOCKED_COMMANDS=(
  'podman container inspect'
  'podman network inspect'
  'podman volume inspect'
  'podman secret inspect'
  'podman image inspect'
  'podman system info'
  'podman mount'
  'podman exec'
  'podman cp'

  'complete'
  'iptables'
  'tcpdump'
  'rsync'
  'nmap'
  'curl'
  'wget'
  'scp'
  'ssh'

  'killall'
  'strace'
  'pkill'
  'htop'
  'free'
  'lsof'
  'kill'
  'top'
  'gdb'
  'ps'
  'df'

  'modprobe'
  'swapoff'
  'umount'
  'swapon'
  'insmod'
  'rmmod'
  'mount'

  'shutdown'
  'loginctl'
  'poweroff'
  'reboot'
  'halt'

  'apt-get'
  'snap'
  'apt'

  'python3'
  'python'
  'py'

  'bash'
  'zsh'
  'awk'
  '^sh'

  'shopt'
  'bind'
  'sed'
  'set'
  'su'
)

# === Commands blocked outside home dir ===
CONTEXT_BLOCKED_COMMANDS=(ls cd cat nano vim less more tail)

in_home_dir() {
  [[ "$(realpath "$PWD")" == "$HOME_DIR"* ]]
}

# --- Block global commands ---
block_global() {
  local cmd="$1"
  local normalized_cmd="$cmd"
  
  local cmd_part="${cmd%% *}"
  local args_part="${cmd#* }"
  
  if [[ "$cmd_part" == /* ]]; then
    cmd_part="$(basename "$cmd_part")"
    normalized_cmd="$cmd_part"
    if [[ "$args_part" != "$cmd" ]]; then
      normalized_cmd="$cmd_part $args_part"
    fi
  fi
  
  # Check against blocked patterns
  for pattern in "${GLOBAL_BLOCKED_COMMANDS[@]}"; do
    if [[ "$normalized_cmd" == $pattern* ]] || [[ "$cmd" == $pattern* ]]; then
      safe_echo "❌ Command '$cmd' is globally blocked."
      return 1
    fi
    
    if [[ "$cmd" =~ $pattern ]]; then
      safe_echo "❌ Command '$cmd' is globally blocked."
      return 1
    fi
  done
  return 0
}

# --- Block contextual commands outside home ---
block_context() {
  local cmd="$1"

  # Split cmd into command and all arguments
  local cmd_name="${cmd%% *}"
  local args_part="${cmd#* }"
  
  local base_cmd_name="$cmd_name"
  if [[ "$cmd_name" == /* ]]; then
    base_cmd_name="$(basename "$cmd_name")"
  fi

  # Check if this is a contextual command
  for forbidden in "${CONTEXT_BLOCKED_COMMANDS[@]}"; do
    if [[ "$base_cmd_name" == "$forbidden" ]]; then
      # Block if command itself is called with absolute path
      if [[ "$cmd_name" == /* ]]; then
        safe_echo "❌ Command '$base_cmd_name' with absolute executable path is blocked."
        return 1
      fi
      
      # Block if ANY argument is an absolute path (prevents accessing files outside home)
      if [[ "$args_part" != "$cmd" ]]; then
        # Convert arguments to array and check each one
        read -ra args_array <<< "$args_part"
        for arg in "${args_array[@]}"; do
          if [[ "$arg" == /* ]]; then
            safe_echo "❌ Command '$base_cmd_name' with absolute path argument '$arg' is blocked."
            return 1
          fi
        done
      fi
      
      # Block command completely if used outside home directory
      if ! in_home_dir; then
        safe_echo "❌ Command '$base_cmd_name' is blocked outside $HOME_DIR"
        return 1
      fi
    fi
  done
  return 0
}

# --- Unified restricted command execution ---
restricted_run() {
  local cmd="$1"
  block_global "$cmd" && block_context "$cmd" && eval "$cmd" 2>&1 | sed "s|$SCRIPT_DIR|...|g"
}

# --- Handle SSH one-liner commands ---
if [[ -n "$CMD" ]]; then
  restricted_run "$CMD" || exit 1
  exit $?
fi

# --- Interactive SSH session ---
safe_echo "👋 Welcome back $USER!"
safe_echo "🔐 You are operating in restricted mode."
safe_echo "🍁 Hit CTRL+C to exit the session, use 's' command to view system stats."
sleep 2s
echo

create_progress_bar() {
  local percentage=$1
  local bar_length=20
  local filled_chars=$(( percentage * bar_length / 100 ))
  
  local filled=$(printf "%*s" "$filled_chars" "" | tr ' ' '#')
  local empty=$(printf "%*s" $((bar_length - filled_chars)) "" | tr ' ' ' ')
  
  printf "[%s%s]" "$filled" "$empty"
}

display_stats() {
  echo "📊 System Stats: ($(TZ='Asia/Kolkata' date '+%r'))"
  
  # CPU usage
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
  CPU_USAGE_INT=${CPU_USAGE%.*}  # Convert to integer for bar calculation
  CPU_BAR=$(create_progress_bar "$CPU_USAGE_INT")
  printf "CPU:    %s %.1f%%\n" "$CPU_BAR" "$CPU_USAGE"
  
  # Memory usage
  MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
  MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
  MEM_PERCENT=$(( MEM_USED * 100 / MEM_TOTAL ))
  MEM_BAR=$(create_progress_bar "$MEM_PERCENT")
  printf "Memory: %s %d%% (%d/%d MB)\n" "$MEM_BAR" "$MEM_PERCENT" "$MEM_USED" "$MEM_TOTAL"
  
  # Disk usage
  DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
  DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
  DISK_PERCENT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
  DISK_BAR=$(create_progress_bar "$DISK_PERCENT")
  printf "Disk:   %s %d%% (%s/%s)\n" "$DISK_BAR" "$DISK_PERCENT" "$DISK_USED" "$DISK_TOTAL"
  
  echo
  safe_echo "🟢 Active Containers:"
  podman ps
  echo
}

display_stats

# Interactive loop with restricted execution
while true; do
  IFS= read -e -p "\$($(whoami)): " CMD || break # -e enables readline
  CMD=$(echo "$CMD" | xargs) # trim spaces
  [[ -z "$CMD" ]] && continue
  
  if [[ "$CMD" == "s" ]]; then
    clear
    display_stats
  else
    restricted_run "$CMD"
  fi
done

#!/bin/bash

# docs: https://mag37.org/posts/guide_podman_quadlets/
set -euo pipefail

usage() {
  echo "⚡ Usage: $0 -a APP_NAME -p APP_PORT -g GREEN_PORT -b BLUE_PORT -v VERSION -f [true|false] -g [true|false]"
  echo "  -a APP_NAME      : Name of the application (required)"
  echo "  -p APP_PORT      : Port the application listens on inside container"
  echo "  -g GREEN_PORT    : Deployment port for green mode on host network"
  echo "  -b BLUE_PORT     : Deployment port for blue mode on host network"
  echo "  -v VERSION       : Version of the application/image"
  echo "  -f [true|false]  : Flip the deployment mode (default: false)"
  echo "  -r [true|false]  : Retrieve the image from ghcr.io (default: false)"
  exit 1
}

# --- 1. Parse inputs & validation ---
APP_NAME=""
APP_PORT=""
GREEN_PORT=""
BLUE_PORT=""
FLIP="false"
VERSION=""
RETRIEVE="false"

while getopts "a:p:g:b:v:f:r:" opt; do
  case ${opt} in
    a) APP_NAME="$OPTARG" ;;
    p) APP_PORT="$OPTARG" ;;
    g) GREEN_PORT="$OPTARG" ;;
    b) BLUE_PORT="$OPTARG" ;;
    v) VERSION="$OPTARG" ;;
    f) FLIP="$OPTARG" ;;
    r) RETRIEVE="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ "$FLIP" != "true" && "$FLIP" != "false" ]]; then
  echo "❌ FLIP must be 'true' or 'false'"
  usage
fi

if [[ "$RETRIEVE" != "true" && "$RETRIEVE" != "false" ]]; then
  echo "❌ RETRIEVE must be 'true' or 'false'"
  usage
fi

if [[ "$FLIP" == "false" ]]; then
  [[ -z "$APP_NAME" || -z "$APP_PORT" || -z "$GREEN_PORT" || -z "$BLUE_PORT" || -z "$VERSION" ]] && {
    echo "❌ When FLIP=false, -a, -p, -dg, -db, and -v are required"
    usage
  }
elif [[ -z "$APP_NAME" ]]; then
  echo "❌ When FLIP=true, -a is required"
  usage
fi

# --- 2. Prepare Constants ---
IMAGE="ghcr.io/hack-nocturne/$APP_NAME:$VERSION"
CONF_FILE="/etc/nginx/conf.d/active_color.conf"
ENV_FILE="$HOME/.config/$APP_NAME.env"

# --- 3. First thing first [Secure the ENV] ---
declare -a SECRET_NAMES=()
if [[ "$FLIP" == "false" ]]; then
  if [[ ! -e "$ENV_FILE" ]]; then
    echo "❌ Environment file '$ENV_FILE' not found!"
    exit 1
  else
    while IFS='=' read -r key value; do
      [[ -z "$key" || "$key" == \#* ]] && continue
      key=$(echo "$key" | xargs)
      
      # Remove surrounding quotes from value if any
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      
      secret_name="${APP_NAME}_${key,,}" # to lowercase
      echo "Creating secret: $secret_name"
      
      # Create secret from the value
      printf "$value" | podman secret create --replace "$secret_name" -
      SECRET_NAMES+=("$secret_name")
    done < "$ENV_FILE"

    rm -f "$ENV_FILE"
    echo "🔐 Created ${#SECRET_NAMES[@]} individual secrets"
  fi
fi

# --- 4. Extract current active color ---
current_color=$(grep -oP 'set \$active_color "\K(blue|green)(?=";)' "$CONF_FILE" || echo "blue")
echo "👋 Current active deployment: $current_color"

# --- 5. Invert the color switch ---
if [[ "$current_color" == "green" ]]; then
  deploy_port="$BLUE_PORT"
  new_color="blue"
else
  deploy_port="$GREEN_PORT"
  new_color="green"
fi

container="${APP_NAME}_${new_color}"
target_containers=($(podman ps -a --format '{{.Names}}' --filter "name=^${container}"))

# --- 6. Handle FLIP mode ---
if [[ "$FLIP" == "true" ]]; then
  if [ ${#target_containers[@]} -eq 0 ]; then
    echo "❌ No containers found for $new_color deployment"
    exit 1
  fi

  for tc in "${target_containers[@]}"; do
    if ! podman inspect -f '{{.State.Running}}' "$tc" 2>/dev/null | grep -q true; then
      echo "❌ Container '$tc' is not running for $new_color deployment"
      exit 1
    fi
  done

  echo "🪶 Switching traffic from $current_color to $new_color"
  echo "set \$active_color \"$new_color\";" | sudo tee "$CONF_FILE" > /dev/null
  sudo nginx -s reload

  echo "✅ Deployment switched to $new_color"
  sleep 5s
  exit 0
fi

# --- 7. Pull the $IMAGE in RETRIEVE mode ---
if [[ "$RETRIEVE" == "true" ]]; then
  echo "🔃 Pulling image from: $IMAGE"
  podman pull "$IMAGE"
fi

target="${container}-${deploy_port}"
sysd_target="${container}@${deploy_port}"
systemctl --user enable podman-auto-update.service podman-auto-update.timer --now

# --- 8. Stop old container silently ---
if podman ps -a --format '{{.Names}}' | grep -wq "$target"; then
  systemctl --user stop $sysd_target
  echo "✅ Stopped old container: $target"
  sleep 2s
else
  echo "⚠️ No old container found for $new_color deployment, continuing..."
fi

# --- 9. Prepare new Quadlet (podman-rootless) ---
target_dir="$HOME/.config/containers/systemd"
mkdir -p "$target_dir"

# Build the Secret lines for the Quadlet file
SECRET_LINES=""
if [[ ${#SECRET_NAMES[@]} -gt 0 ]]; then
  for secret_name in "${SECRET_NAMES[@]}"; do
    # Extract the env var name from secret name (remove app prefix)
    env_var_name=$(echo "$secret_name" | sed "s/^${APP_NAME}_//")
    env_var_name=$(echo "$env_var_name" | tr '[:lower:]' '[:upper:]') # Convert back to uppercase
    SECRET_LINES+="Secret=${secret_name},type=env,target=${env_var_name}"$'\n'
  done
fi

tee "$target_dir/$container@.container" > /dev/null <<EOF
[Unit]
Description=$APP_NAME container for $new_color deployment on port %i
Wants=network-online.target
After=network-online.target

[Container]
PublishPort=127.0.0.1:$deploy_port:$APP_PORT
ContainerName=${container}-%i
NoNewPrivileges=true
DropCapability=all
ReadOnly=true
Image=$IMAGE
${SECRET_LINES}

[Service]
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target default.target
EOF

# --- 10. Start the new Quadlet ---
systemctl --user daemon-reload
systemctl --user start $sysd_target

echo "✅ Application '$APP_NAME:$VERSION' is now live for '$new_color' deployment (container: $target)"
echo "👟 Use '$0 -a $APP_NAME -f true' to switch traffic to this deployment"

# --- [Signing Off] ---

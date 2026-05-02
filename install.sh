#!/bin/sh
set -e

PLIST_LABEL="com.tailscale.serve-watcher"
PLIST_NAME="${PLIST_LABEL}.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
INSTALL_DIR="$HOME/Library/TailscaleServeWatcher"
LOG_DIR="$HOME/Library/Logs/TailscaleServeWatcher"
DEFAULT_CONFIG="$HOME/.config/tailscale/serve.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== TailscaleServeWatcher Installer ==="
echo ""

# Prompt for config file path
printf "Config file path [%s]: " "$DEFAULT_CONFIG"
read -r CONFIG_FILE
CONFIG_FILE="${CONFIG_FILE:-$DEFAULT_CONFIG}"
CONFIG_FILE="$(eval echo "$CONFIG_FILE")"  # expand ~ if entered manually

# Check tailscale is available
if ! command -v tailscale >/dev/null 2>&1; then
    echo "ERROR: 'tailscale' not found in PATH. Install Tailscale first." >&2
    exit 1
fi

# Create directories
mkdir -p "$INSTALL_DIR" "$LOG_DIR" "$(dirname "$CONFIG_FILE")" "$LAUNCH_AGENTS_DIR"

# Copy script
cp "$SCRIPT_DIR/apply-config.sh" "$INSTALL_DIR/apply-config.sh"
chmod +x "$INSTALL_DIR/apply-config.sh"

# Generate plist from template
sed \
    -e "s|INSTALL_DIR|$INSTALL_DIR|g" \
    -e "s|CONFIG_FILE_PATH|$CONFIG_FILE|g" \
    -e "s|LOG_DIR|$LOG_DIR|g" \
    "$SCRIPT_DIR/$PLIST_NAME" > "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "Installed agent plist to $LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Create example config if none exists
if [ ! -f "$CONFIG_FILE" ]; then
    if [ -f "$SCRIPT_DIR/serve.example.json" ]; then
        cp "$SCRIPT_DIR/serve.example.json" "$CONFIG_FILE"
        echo "Created example config at $CONFIG_FILE — edit it to add your bindings."
    else
        echo "{}" > "$CONFIG_FILE"
        echo "Created empty config at $CONFIG_FILE"
    fi
fi

# Unload existing agent if running
launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true

# Load the agent
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
echo "Agent loaded. Applying config now..."

# Run immediately
CONFIG_FILE="$CONFIG_FILE" "$INSTALL_DIR/apply-config.sh" || true

echo ""
echo "Done. The watcher is running."
echo "  Config file : $CONFIG_FILE"
echo "  Logs        : $LOG_DIR/"
echo "  To uninstall: sh uninstall.sh"

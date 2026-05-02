#!/bin/sh
set -e

PLIST_LABEL="com.tailscale.serve-watcher"
PLIST_NAME="${PLIST_LABEL}.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
INSTALL_DIR="$HOME/Library/TailscaleServeWatcher"
LOG_DIR="$HOME/Library/Logs/TailscaleServeWatcher"

echo "=== TailscaleServeWatcher Uninstaller ==="

# Stop and unload agent
if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME" ]; then
    launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null && echo "Agent unloaded." || echo "Agent was not running."
    rm -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
    echo "Removed plist."
else
    echo "No agent plist found at $LAUNCH_AGENTS_DIR/$PLIST_NAME"
fi

# Remove installed files
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "Removed $INSTALL_DIR"
fi

echo ""
echo "Uninstall complete. Your config file and logs were left in place."
echo "  Logs: $LOG_DIR/"
echo "  To remove logs: rm -rf $LOG_DIR"

#!/bin/sh
# Applies the Tailscale serve config file. Invoked by launchd on file change.
set -e

if [ -z "$CONFIG_FILE" ]; then
    echo "ERROR: CONFIG_FILE environment variable is not set" >&2
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

echo "$(date): Applying tailscale serve config from $CONFIG_FILE"
tailscale serve set-config --all "$CONFIG_FILE"
echo "$(date): Done"

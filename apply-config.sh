#!/bin/sh
# Reads a JSON config and applies tailscale serve port bindings.
# Invoked by launchd on file change via WatchPaths.
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

tailscale serve reset 2>/dev/null || true

python3 - "$CONFIG_FILE" <<'EOF'
import json, subprocess, sys

config = json.load(open(sys.argv[1]))

for route in config.get("routes", []):
    port   = route["https_port"]
    target = route["target"]
    print(f"  port {port} -> {target}")
    subprocess.run(
        ["tailscale", "serve", f"--https={port}", "--bg", target],
        check=True
    )
EOF

echo "$(date): Done"

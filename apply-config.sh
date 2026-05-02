#!/bin/sh
# Reads a JSON config and applies tailscale serve path bindings.
# Runs on file change via launchd WatchPaths.
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

HTTPS_PORT=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('https_port', 443))" "$CONFIG_FILE")

# Clear existing serve bindings
tailscale serve reset 2>/dev/null || true

# Apply each route
python3 - "$CONFIG_FILE" "$HTTPS_PORT" <<'EOF'
import json, subprocess, sys

config = json.load(open(sys.argv[1]))
port   = sys.argv[2]

for route in config.get("routes", []):
    path   = route["path"]
    target = route["target"]
    print(f"  {path} -> {target}")
    subprocess.run(
        ["tailscale", "serve", f"--https={port}", f"--set-path={path}", "--bg", target],
        check=True
    )
EOF

echo "$(date): Done"

# Design: TailscaleServeWatcher Architecture

Type: hld

## Overview

TailscaleServeWatcher is a macOS launchd agent that watches a JSON config file on disk and automatically re-applies it to `tailscale serve` whenever the file changes. It enables declarative, file-driven management of multiple Tailscale serve bindings without manual CLI intervention.

## Problem

`tailscale serve set-config --all <file>` applies all serve bindings from a JSON file declaratively, but there is no native mechanism to re-apply the config automatically when the file changes. Users must remember to re-run the command after every edit.

## Solution

Use macOS launchd's `WatchPaths` key to trigger a lightweight shell script whenever the config file is modified. launchd monitors the filesystem event natively (via kqueue), so no polling or third-party watcher binary is required.

## Components

### 1. `apply-config.sh`
A shell script that runs:
```sh
tailscale serve set-config --all "$CONFIG_FILE"
```
It reads `CONFIG_FILE` from an environment variable set by the launchd plist. On error it logs to the system log.

### 2. `com.tailscale.serve-watcher.plist`
A launchd `LaunchAgent` plist with:
- `WatchPaths` — points to the user's config file; launchd triggers the job on any write
- `EnvironmentVariables` — passes `CONFIG_FILE` path to the script
- `StandardOutPath` / `StandardErrorPath` — logs to `~/Library/Logs/TailscaleServeWatcher/`
- `RunAtLoad true` — applies config once on login so bindings survive reboots

### 3. `install.sh`
Interactive installer that:
1. Prompts for the config file path (default `~/.config/tailscale/serve.json`)
2. Creates the log directory
3. Copies `apply-config.sh` to `~/Library/TailscaleServeWatcher/`
4. Generates the plist with the correct paths and installs it to `~/Library/LaunchAgents/`
5. Loads the agent with `launchctl bootstrap`
6. Runs apply immediately

### 4. `uninstall.sh`
Stops and removes the launchd agent and installed files cleanly.

### 5. `serve.example.json`
An annotated example config file using the Tailscale service config format, showing common patterns (HTTP proxy, HTTPS proxy, path routing, TCP).

## Data Flow

```
User edits serve.json
        │
        ▼
  launchd (WatchPaths)
        │  detects write
        ▼
  apply-config.sh
        │
        ▼
  tailscale serve set-config --all serve.json
        │
        ▼
  tailscaled applies new bindings
```

## Constraints

- macOS only (launchd is macOS/Darwin-specific)
- Requires Tailscale CLI in PATH
- The config file must exist before the agent is loaded (launchd will trigger on creation too, but `set-config` will fail on an empty/missing file)
- `RunAtLoad` means bindings are re-applied on every login, which is the desired behavior for a persistent VPN setup

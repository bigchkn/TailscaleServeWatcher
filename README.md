# TailscaleServeWatcher

A macOS launchd agent that watches a JSON config file and automatically re-applies your `tailscale serve` bindings whenever the file changes.

## How it works

`tailscale serve set-config --all <file>` declaratively applies all serve bindings from a JSON file. TailscaleServeWatcher uses launchd's `WatchPaths` to trigger that command whenever you save the file — no polling, no third-party dependencies.

```
Edit serve.json  →  launchd detects write  →  apply-config.sh  →  tailscale serve set-config
```

## Requirements

- macOS
- [Tailscale](https://tailscale.com/download) installed and authenticated

## Install

```sh
git clone https://github.com/bigchkn/TailscaleServeWatcher.git
cd TailscaleServeWatcher
sh install.sh
```

The installer will prompt for your config file path (default: `~/.config/tailscale/serve.json`) and start the watcher immediately.

## Config file format

The config file uses the [Tailscale service configuration format](https://tailscale.com/kb/1589/tailscale-services-configuration-file). See `serve.example.json` for a working starting point:

```json
{
  "TCP": {
    "443": { "HTTPS": true }
  },
  "Web": {
    "my-machine.tailnet.ts.net:443": {
      "Handlers": {
        "/api/":       { "Proxy": "http://127.0.0.1:8080" },
        "/dashboard/": { "Proxy": "http://127.0.0.1:3000" }
      }
    }
  }
}
```

Get the current hostname to use as the key:
```sh
tailscale status --json | jq -r '.Self.DNSName' | tr -d '.'
# or just: tailscale serve get-config --all /tmp/current.json
```

## Usage

After install, just edit your config file and save. Changes are applied within seconds.

**View logs:**
```sh
tail -f ~/Library/Logs/TailscaleServeWatcher/stdout.log
tail -f ~/Library/Logs/TailscaleServeWatcher/stderr.log
```

**Re-apply manually:**
```sh
CONFIG_FILE=~/.config/tailscale/serve.json ~/Library/TailscaleServeWatcher/apply-config.sh
```

**Check current bindings:**
```sh
tailscale serve status
```

## Uninstall

```sh
sh uninstall.sh
```

This stops the agent and removes installed files. Your config file and logs are left in place.

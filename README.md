# shah1-v5

A lightweight FRP-based tunnel setup that keeps the original project logic intact while making installation simple and repeatable from GitHub.

## What this repository contains

- `shah1.sh` — the main installation and management script.
- `install.sh` — a one-click installer that downloads the main script from GitHub and runs it.

## Main features

- Online download of FRP and ShadowTLS during installation
- systemd-managed services
- validation before activation
- idempotent installation behavior
- no changes to Xray, user panels, or unrelated services
- menu-driven install / status / verify / remove / exit flow

## One-click installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh)
```

## Install directly as a root-managed binary

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh)
```

## Repository files

- `shah1.sh` is the source of truth.
- `install.sh` downloads and executes it from the GitHub raw URL.

## Notes

- The installer downloads FRP and ShadowTLS from their official GitHub releases.
- No executables are embedded directly in the script.
- The project logic is preserved from `shah1.sh` as requested, with only GitHub-compatible packaging and installation flow added.

# Codex CLI for Termux

Install or update [OpenAI Codex CLI](https://github.com/openai/codex) on Termux with a single command.

## Before installation

Update Termux packages first:

```sh
pkg update -y && pkg upgrade -y
```

## Installation

```sh
curl -fsSL https://github.com/rivolink/codex-termux/raw/main/install.sh | sh
```

## What the script does

1. **Installs dependencies** - `rust`, `openssl`, `pkg-config` via pkg
2. **Configures cargo profile** - adds a `termux` profile to `~/.cargo/config.toml` optimized for low-memory devices
3. **Fetches latest version** - detects the latest stable `rust-v*` tag from GitHub
4. **Builds and installs codex-cli** - using cargo with the `termux` profile
5. **Creates symlink** - links the binary to `/data/data/com.termux/files/usr/bin/codex`

## Why a custom cargo profile?

On low-end Android devices, the default release build can run out of memory.  
The `termux` profile reduces memory usage during compilation:

```toml
[profile.termux]
inherits = "release"
lto = "off"
codegen-units = 8
opt-level = "s"
```

## After installation

Authenticate with your OpenAI account:

```sh
codex login
```

## Updating

Run the same installation command to update to the latest version:

```sh
curl -fsSL https://github.com/rivolink/codex-termux/raw/main/install.sh | sh
```

## Requirements

- Termux on Android
- Internet connection
- ~30 minutes on low-end devices for compilation

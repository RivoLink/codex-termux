#!/bin/sh
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

success() {
    printf "${GREEN}[OK]${NC} %s\n" "$1"
}

warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
    exit 1
}

# Check if running on Termux
if [ ! -d "/data/data/com.termux" ]; then
    error "This script is designed for Termux only."
fi

CARGO_BIN="$HOME/.cargo/bin"
CARGO_CONFIG="$HOME/.cargo/config.toml"

TERMUX_BIN="/data/data/com.termux/files/usr/bin"

# Step 1: Install dependencies if needed
if ! command -v cargo >/dev/null 2>&1; then
    info "Installing dependencies..."
    pkg install -y rust openssl pkg-config
    success "Dependencies installed."
else
    success "Dependencies already installed."
fi

# Step 2: Setup cargo profile for Termux (low memory usage)
info "Setting up cargo profile 'termux'..."

mkdir -p "$HOME/.cargo"

# Check if profile.termux already exists
if [ -f "$CARGO_CONFIG" ] && grep -q "\[profile\.termux\]" "$CARGO_CONFIG"; then
    success "Cargo profile 'termux' already configured."
else
    info "Adding 'termux' profile to $CARGO_CONFIG..."
    cat >> "$CARGO_CONFIG" << 'EOF'

[profile.termux]
inherits = "release"
lto = "off"
codegen-units = 8
opt-level = "s"
EOF
    success "Cargo profile 'termux' added."
fi

# Step 3: Detect latest stable tag from GitHub
info "Fetching latest stable codex version from GitHub..."

LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/openai/codex/tags" | \
    grep -oE '"name":\s*"rust-v[0-9]+\.[0-9]+\.[0-9]+"' | \
    head -1 | \
    sed 's/"name":\s*"//;s/"//')

if [ -z "$LATEST_TAG" ]; then
    error "Failed to fetch latest tag from GitHub."
fi

success "Latest stable version: $LATEST_TAG"

# Step 4: Install/Update codex via cargo with termux profile
info "Installing codex-cli (this may take a while on low-end devices)..."
warn "On low-end devices, this can take 20-30 minutes. Please be patient."

cargo install --git https://github.com/openai/codex \
    --tag "$LATEST_TAG" \
    codex-cli \
    --force \
    --locked \
    --profile termux

success "codex-cli installed successfully."

# Step 5: Create symlink in Termux bin if not exists
info "Setting up codex in PATH..."

CODEX_SRC="$CARGO_BIN/codex"
CODEX_DST="$TERMUX_BIN/codex"

if [ -L "$CODEX_DST" ]; then
    info "Symlink already exists, updating..."
    rm -f "$CODEX_DST"
fi

if [ -f "$CODEX_SRC" ]; then
    ln -s "$CODEX_SRC" "$CODEX_DST"
    success "Symlink created: $CODEX_DST -> $CODEX_SRC"
else
    error "codex binary not found at $CODEX_SRC"
fi

# Final message
echo ""
success "========================================="
success "  Codex CLI installation complete!"
success "========================================="
echo ""
info "Version installed: $LATEST_TAG"
info "You can now run 'codex' from anywhere in Termux."
echo ""
info "To authenticate, run:"
echo "  codex login"
echo ""

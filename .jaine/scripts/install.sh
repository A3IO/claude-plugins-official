#!/opt/homebrew/bin/bash
#
# JAINE Plugins Install Script
# Sets up the local marketplace for Claude Code
#
# Usage:
#   ./install.sh           - Full install (add marketplace + install plugins)
#   ./install.sh --add     - Only add marketplace
#   ./install.sh --plugins - Only install plugins
#   ./install.sh --status  - Check installation status
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Plugins we use (subset of all available)
ENABLED_PLUGINS=(
    "hookify"
    "pr-review-toolkit"
    "commit-commands"
    "feature-dev"
    "code-review"
    "frontend-design"
    "ralph-wiggum"
    "agent-sdk-dev"
)

check_status() {
    log_info "Checking installation status..."
    echo ""

    echo "Repository: $REPO_ROOT"
    echo "Branch: $(git -C "$REPO_ROOT" branch --show-current)"
    echo ""

    # Check if marketplace is added
    if [[ -f ~/.claude/plugins/marketplaces/jaine-plugins/marketplace.json ]]; then
        log_success "Marketplace 'jaine-plugins' is installed"
    else
        log_warn "Marketplace 'jaine-plugins' is NOT installed"
    fi

    echo ""
    echo "Installed plugins from jaine-plugins:"

    for plugin in "${ENABLED_PLUGINS[@]}"; do
        if grep -q "\"${plugin}@jaine-plugins\": true" ~/.claude/settings.json 2>/dev/null; then
            log_success "  $plugin"
        else
            log_warn "  $plugin (not installed)"
        fi
    done
}

add_marketplace() {
    log_info "Adding jaine-plugins marketplace..."

    # Check if already added
    if [[ -d ~/.claude/plugins/marketplaces/jaine-plugins ]]; then
        log_warn "Marketplace already exists. Removing old version..."
        rm -rf ~/.claude/plugins/marketplaces/jaine-plugins
    fi

    # Create symlink to our repo
    mkdir -p ~/.claude/plugins/marketplaces
    ln -sf "$REPO_ROOT" ~/.claude/plugins/marketplaces/jaine-plugins

    log_success "Marketplace added!"
    echo ""
    echo "To verify, run: ls -la ~/.claude/plugins/marketplaces/"
}

install_plugins() {
    log_info "Installing plugins from jaine-plugins..."
    echo ""

    echo "The following plugins will be installed:"
    for plugin in "${ENABLED_PLUGINS[@]}"; do
        echo "  - $plugin"
    done

    echo ""
    echo "Note: This script shows commands to run."
    echo "Claude Code plugin commands must be run from within Claude Code."
    echo ""

    log_info "Run these commands in Claude Code:"
    echo ""

    # First uninstall from official
    echo "# Uninstall from official marketplace (if installed):"
    for plugin in "${ENABLED_PLUGINS[@]}"; do
        echo "/plugin uninstall $plugin@claude-code-plugins"
    done

    echo ""
    echo "# Install from jaine-plugins:"
    for plugin in "${ENABLED_PLUGINS[@]}"; do
        echo "/plugin install $plugin@jaine-plugins"
    done

    echo ""
    log_warn "Copy and run these commands in Claude Code!"
}

show_usage() {
    echo "JAINE Plugins Install Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  (none)     Full install instructions"
    echo "  --add      Add marketplace symlink"
    echo "  --plugins  Show plugin install commands"
    echo "  --status   Check installation status"
    echo ""
}

# Main
cd "$REPO_ROOT"

case "${1:-}" in
    --add)
        add_marketplace
        ;;
    --plugins)
        install_plugins
        ;;
    --status)
        check_status
        ;;
    --help|-h)
        show_usage
        ;;
    "")
        add_marketplace
        echo ""
        install_plugins
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

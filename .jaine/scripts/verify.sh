#!/opt/homebrew/bin/bash
#
# JAINE Plugins Verify Script
# Verifies integrity of our modifications against manifest checksums
#
# Usage:
#   ./verify.sh          - Verify all modifications
#   ./verify.sh hookify  - Verify specific plugin
#   ./verify.sh --update - Update checksums in manifest
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
MANIFEST="$REPO_ROOT/.jaine/manifest.yaml"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

verify_file() {
    local file="$1"
    local expected="$2"

    if [[ ! -f "$REPO_ROOT/$file" ]]; then
        log_error "$file - FILE MISSING"
        return 1
    fi

    local actual=$(md5 -q "$REPO_ROOT/$file")

    if [[ "$expected" == "$actual" ]]; then
        log_success "$file"
        return 0
    else
        log_error "$file - CHECKSUM MISMATCH"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

verify_all() {
    log_info "Verifying all modifications..."
    echo ""

    local all_ok=true

    # Get all files from manifest
    local files=$(yq -r '.modifications[].files[].path' "$MANIFEST" 2>/dev/null || echo "")

    for file in $files; do
        local expected=$(yq -r ".modifications[].files[] | select(.path == \"$file\") | .our_checksum" "$MANIFEST" | head -1)
        if ! verify_file "$file" "$expected"; then
            all_ok=false
        fi
    done

    echo ""
    if [[ "$all_ok" == "true" ]]; then
        log_success "All modifications verified!"
        return 0
    else
        log_error "Some verifications failed!"
        return 1
    fi
}

verify_plugin() {
    local plugin="$1"
    log_info "Verifying plugin: $plugin"
    echo ""

    local all_ok=true

    # Get files for specific plugin
    local files=$(yq -r ".modifications.$plugin.files[].path" "$MANIFEST" 2>/dev/null || echo "")

    if [[ -z "$files" ]]; then
        log_warn "No modifications tracked for plugin: $plugin"
        return 0
    fi

    for file in $files; do
        local expected=$(yq -r ".modifications.$plugin.files[] | select(.path == \"$file\") | .our_checksum" "$MANIFEST")
        if ! verify_file "$file" "$expected"; then
            all_ok=false
        fi
    done

    echo ""
    if [[ "$all_ok" == "true" ]]; then
        log_success "Plugin $plugin verified!"
        return 0
    else
        log_error "Plugin $plugin verification failed!"
        return 1
    fi
}

update_checksums() {
    log_info "Updating checksums in manifest..."
    echo ""

    local files=$(yq -r '.modifications[].files[].path' "$MANIFEST" 2>/dev/null || echo "")

    for file in $files; do
        if [[ -f "$REPO_ROOT/$file" ]]; then
            local checksum=$(md5 -q "$REPO_ROOT/$file")
            log_info "Updated: $file -> $checksum"
        else
            log_warn "Skipped (missing): $file"
        fi
    done

    echo ""
    log_warn "Manual update required - edit .jaine/manifest.yaml with new checksums"
    echo "Use: yq -i '.modifications.PLUGIN.files[] | select(.path == \"PATH\").our_checksum = \"CHECKSUM\"' .jaine/manifest.yaml"
}

show_status() {
    log_info "JAINE Plugins Status"
    echo ""

    echo "Manifest: $MANIFEST"
    echo "Upstream commit: $(yq -r '.upstream_commit' "$MANIFEST")"
    echo "Last sync: $(yq -r '.last_sync' "$MANIFEST")"
    echo ""

    echo "Modified plugins:"
    yq -r '.modifications | keys | .[]' "$MANIFEST" 2>/dev/null | while read plugin; do
        local count=$(yq -r ".modifications.$plugin.files | length" "$MANIFEST")
        local pr=$(yq -r ".modifications.$plugin.pr_number" "$MANIFEST")
        echo "  - $plugin ($count files, PR #$pr)"
    done

    echo ""
    echo "Unmodified plugins: $(yq -r '.unmodified_plugins | length' "$MANIFEST")"
}

# Main
cd "$REPO_ROOT"

if ! command -v yq &> /dev/null; then
    log_error "yq is required but not installed. Install with: brew install yq"
    exit 1
fi

case "${1:-}" in
    --update)
        update_checksums
        ;;
    --status)
        show_status
        ;;
    "")
        verify_all
        ;;
    *)
        verify_plugin "$1"
        ;;
esac

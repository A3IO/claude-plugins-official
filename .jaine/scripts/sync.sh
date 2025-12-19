#!/opt/homebrew/bin/bash
#
# JAINE Plugins Sync Script
# Synchronizes local fork with upstream while preserving our modifications
#
# Usage:
#   ./sync.sh check     - Check for upstream updates (dry-run)
#   ./sync.sh preview   - Preview merge result in temp branch
#   ./sync.sh sync      - Perform sync (with confirmation)
#   ./sync.sh rollback  - Rollback to pre-sync state
#
# Requirements:
#   - bash 4+ (for associative arrays)
#   - yq (for YAML parsing)
#   - git with upstream remote configured
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST="$REPO_ROOT/.jaine/manifest.yaml"
CHECKSUMS_DIR="$REPO_ROOT/.jaine/checksums"

# Functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_requirements() {
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed. Install with: brew install yq"
        exit 1
    fi

    if ! git remote | grep -q upstream; then
        log_error "upstream remote not configured"
        exit 1
    fi
}

get_manifest_value() {
    local key="$1"
    yq -r "$key" "$MANIFEST"
}

get_current_upstream_commit() {
    git ls-remote upstream refs/heads/main | cut -f1 | head -c7
}

get_local_upstream_commit() {
    get_manifest_value '.upstream_commit'
}

cmd_check() {
    log_info "Checking for upstream updates..."

    git fetch upstream --quiet

    local local_commit=$(get_local_upstream_commit)
    local remote_commit=$(get_current_upstream_commit)

    echo ""
    echo "Last synced commit: $local_commit"
    echo "Current upstream:   $remote_commit"
    echo ""

    if [[ "$local_commit" == "$remote_commit" ]]; then
        log_success "Already up to date!"
        return 0
    fi

    log_warn "Updates available!"
    echo ""
    echo "Changes since last sync:"
    git log --oneline "$local_commit..upstream/main" | head -20

    echo ""
    echo "Files changed:"
    git diff --stat "$local_commit..upstream/main" | tail -10

    # Check for conflicts with our modifications
    echo ""
    log_info "Checking for potential conflicts with our modifications..."

    local our_files=$(yq -r '.modifications[].files[].path' "$MANIFEST" 2>/dev/null || echo "")
    local has_conflict=false

    for file in $our_files; do
        if git diff --name-only "$local_commit..upstream/main" | grep -q "^$file$"; then
            log_warn "CONFLICT: $file was modified in both upstream and our fork"
            has_conflict=true
        fi
    done

    if [[ "$has_conflict" == "true" ]]; then
        echo ""
        log_error "Potential conflicts detected! Use 'preview' to see details."
        return 1
    else
        log_success "No conflicts with our modifications"
        return 0
    fi
}

cmd_preview() {
    log_info "Creating preview of merge..."

    local backup_branch="jaine-backup-$(date +%Y%m%d-%H%M%S)"
    local preview_branch="jaine-preview-$(date +%Y%m%d-%H%M%S)"

    # Create backup
    git branch "$backup_branch" jaine 2>/dev/null || true

    # Create preview branch
    git checkout -b "$preview_branch" jaine --quiet

    # Try merge
    if git merge upstream/main --no-commit --no-ff 2>/dev/null; then
        log_success "Merge preview successful (no conflicts)"
        echo ""
        echo "Preview changes:"
        git diff --cached --stat

        # Verify our modifications are intact
        echo ""
        log_info "Verifying our modifications..."
        local all_ok=true
        local our_files=$(yq -r '.modifications[].files[].path' "$MANIFEST" 2>/dev/null || echo "")

        for file in $our_files; do
            local expected_checksum=$(yq -r ".modifications[].files[] | select(.path == \"$file\") | .our_checksum" "$MANIFEST" | head -1)
            local actual_checksum=$(md5 -q "$REPO_ROOT/$file" 2>/dev/null || echo "missing")

            if [[ "$expected_checksum" == "$actual_checksum" ]]; then
                log_success "$file - checksum OK"
            else
                log_error "$file - checksum MISMATCH!"
                all_ok=false
            fi
        done

        # Cleanup
        git merge --abort 2>/dev/null || true
        git checkout jaine --quiet
        git branch -D "$preview_branch" --quiet

        if [[ "$all_ok" == "true" ]]; then
            echo ""
            log_success "Preview complete. Safe to sync."
        else
            echo ""
            log_error "Preview complete. CONFLICTS DETECTED - manual resolution required."
            return 1
        fi
    else
        log_error "Merge has conflicts!"
        echo ""
        echo "Conflicting files:"
        git diff --name-only --diff-filter=U

        # Cleanup
        git merge --abort
        git checkout jaine --quiet
        git branch -D "$preview_branch" --quiet 2>/dev/null || true

        return 1
    fi
}

cmd_sync() {
    log_info "Starting sync with upstream..."

    # First run check
    if ! cmd_check; then
        log_error "Check failed. Resolve issues before syncing."
        return 1
    fi

    local local_commit=$(get_local_upstream_commit)
    local remote_commit=$(get_current_upstream_commit)

    if [[ "$local_commit" == "$remote_commit" ]]; then
        log_success "Already up to date!"
        return 0
    fi

    # Confirmation
    echo ""
    read -p "Proceed with sync? (y/N) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Sync cancelled."
        return 0
    fi

    # Create backup
    local backup_branch="jaine-backup-$(date +%Y%m%d-%H%M%S)"
    git branch "$backup_branch" jaine
    log_info "Backup created: $backup_branch"

    # Sync main first
    git checkout main --quiet
    git merge upstream/main --no-edit
    git push origin main

    # Merge into jaine
    git checkout jaine --quiet
    if git merge main --no-edit; then
        log_success "Merge successful!"

        # Update manifest
        local new_commit=$(git rev-parse upstream/main | head -c7)
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        # Update manifest using sed (more portable than yq write)
        sed -i '' "s/upstream_commit: \".*\"/upstream_commit: \"$new_commit\"/" "$MANIFEST"
        sed -i '' "s/last_sync: \".*\"/last_sync: \"$timestamp\"/" "$MANIFEST"

        # Commit manifest update
        git add "$MANIFEST"
        git commit -m "chore: update manifest after sync with upstream $new_commit"

        # Push
        git push origin jaine
        git push origin main

        echo ""
        log_success "Sync complete!"
        echo "Backup branch: $backup_branch"
        echo "To rollback: ./sync.sh rollback $backup_branch"
    else
        log_error "Merge failed! Resolve conflicts manually."
        echo "Backup branch: $backup_branch"
        echo "To rollback: git checkout jaine && git reset --hard $backup_branch"
        return 1
    fi
}

cmd_rollback() {
    local backup_branch="${1:-}"

    if [[ -z "$backup_branch" ]]; then
        echo "Available backup branches:"
        git branch | grep "jaine-backup" || echo "  (none)"
        echo ""
        echo "Usage: ./sync.sh rollback <branch-name>"
        return 1
    fi

    if ! git rev-parse --verify "$backup_branch" &>/dev/null; then
        log_error "Branch '$backup_branch' not found"
        return 1
    fi

    read -p "Rollback to $backup_branch? This will RESET jaine branch. (y/N) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Rollback cancelled."
        return 0
    fi

    git checkout jaine --quiet
    git reset --hard "$backup_branch"
    git push --force-with-lease origin jaine

    log_success "Rollback complete!"
}

show_usage() {
    echo "JAINE Plugins Sync Script"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  check     Check for upstream updates (dry-run)"
    echo "  preview   Preview merge result"
    echo "  sync      Perform sync with confirmation"
    echo "  rollback  Rollback to backup branch"
    echo ""
}

# Main
cd "$REPO_ROOT"
check_requirements

case "${1:-}" in
    check)
        cmd_check
        ;;
    preview)
        cmd_preview
        ;;
    sync)
        cmd_sync
        ;;
    rollback)
        cmd_rollback "${2:-}"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

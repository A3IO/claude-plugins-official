# JAINE Plugins System

Fork of Anthropic's claude-plugins-official with local modifications and deterministic sync.

## Quick Reference

| Command | Description |
|---------|-------------|
| `.jaine/scripts/sync.sh check` | Check for upstream updates |
| `.jaine/scripts/sync.sh preview` | Preview merge result |
| `.jaine/scripts/sync.sh sync` | Sync with upstream |
| `.jaine/scripts/verify.sh` | Verify our modifications |
| `.jaine/scripts/verify.sh --status` | Show system status |

## Architecture

```
main    → synced with upstream/main (no modifications)
jaine   → main + our modifications (working branch)
feat/*  → feature branches for PRs
```

## Current Modifications

### hookify (PR #5)
- **Feature:** Global rules support (`~/.claude/`)
- **Files:** `config_loader.py`, `README.md`, commands, skills
- **Status:** Awaiting review

## Daily Workflow

### Development
```bash
# Edit plugins directly in plugins/
vim plugins/hookify/core/config_loader.py

# Verify changes
.jaine/scripts/verify.sh

# Test in Claude Code (restart may be needed)
```

### Weekly Sync
```bash
# Check for updates
.jaine/scripts/sync.sh check

# If updates available
.jaine/scripts/sync.sh preview
.jaine/scripts/sync.sh sync
```

## Manifest

`.jaine/manifest.yaml` tracks:
- `upstream_commit` - last synced commit
- `modifications` - our changes with checksums
- `unmodified_plugins` - sync as-is

## Troubleshooting

### Plugins not loading
1. Check symlink: `ls -la ~/.claude/plugins/marketplaces/jaine-plugins`
2. Check settings: `cat ~/.claude/settings.json | grep jaine`
3. Clear cache: `rm -rf ~/.claude/plugins/cache/jaine-plugins`

### Sync conflicts
1. Run preview: `.jaine/scripts/sync.sh preview`
2. If conflicts, manually resolve in `jaine` branch
3. Update checksums in manifest

### Rollback
```bash
# List backups
git branch | grep jaine-backup

# Rollback
.jaine/scripts/sync.sh rollback jaine-backup-YYYYMMDD-HHMMSS
```

---
*Created: 2025-12-19*
*Manifest version: 1.0*

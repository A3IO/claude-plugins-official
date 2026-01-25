---
description: Analyze git diff between branches and generate comprehensive BRANCH_CHANGELOG.md. Use before creating pull requests to document all changes with commit history, file analysis, bug fixes, architecture diagrams, and related issues.
argument-hint: "[target-branch] [--depth thorough|standard] [--lang ru|en]"
allowed-tools: ["Read", "Grep", "Glob", "Bash", "Write", "mcp__sequentialthinking__sequentialthinking"]
---

# Changelog Before Merge

Generate comprehensive changelog with date, Issue/PR links, and code verification.

**Output format:** `docs/{YYYY-MM-DD}_BRANCH_CHANGELOG_{branch}_{PR}.md`

## Arguments

- `[target-branch]` - Target branch for diff (default: auto-detect based on worktree pattern)
- `--depth` - Analysis depth (default: standard)
  - `standard` - Commit categorization, 1-3 Mermaid diagrams, basic root cause
  - `thorough` - 5+ diagrams, extended sequential thinking, deep root cause, security review
- `--lang` - Output language (default: ru)
  - `ru` - Russian
  - `en` - English

---

## Workflow

### Step 1: Detect Branches

```bash
CURRENT=$(git rev-parse --abbrev-ref HEAD)

# Auto-detect for /0/SETUP worktree pattern
if [[ "$CURRENT" == */* ]]; then
    PRODUCT_PREFIX=$(echo "$CURRENT" | cut -d'/' -f1)
    DEFAULT_TARGET="${PRODUCT_PREFIX}/main"
else
    DEFAULT_TARGET="main"
fi

TARGET=${1:-$DEFAULT_TARGET}
```

**Auto-detection examples:**
| Current Branch | Default Target |
|----------------|----------------|
| `jaine-speech/fix/voice-key` | `jaine-speech/main` |
| `dotfiles/feat/zsh-update` | `dotfiles/main` |
| `feat/simple-feature` | `main` |

### Step 2: Gather Data

```bash
git log $TARGET..HEAD --oneline | wc -l    # Commit count
git diff $TARGET..HEAD --stat              # File stats
git log $TARGET..HEAD --oneline            # Full history
git diff $TARGET..HEAD                     # Detailed diff
```

### Step 3: Deep Analysis

Use `mcp__sequentialthinking__sequentialthinking` for systematic analysis:

1. **Categorize commits** by type (feat, fix, refactor, docs, test)
2. **Identify bug fixes** - extract root cause and solution
3. **Detect architecture changes** - new modules, patterns, dependencies
4. **Find breaking changes** - removed APIs, changed signatures
5. **Extract related issues** - from commit messages (#123 format)

### Step 4: Generate Document

Create `docs/BRANCH_CHANGELOG_{branch-name}.md` with required sections.

### Step 4.5: Code Verification (MANDATORY)

**After generating draft, MUST verify all claims against code.**

Verification commands:
- Verify method names: `grep "def method_name" src/`
- Verify endpoints: `grep "@app.post.*endpoint" src/`
- Verify new files: `test -f path`
- Verify SSE events: check BOTH server AND client
- Apply corrections and add Verification Report section

---

## Required Sections

1. **Executive Summary** - Overview + emoji bullet points
2. **Statistics Table** - Files, lines, commits, issues
3. **Commit History + Distribution** - Table + type percentages
4. **Architecture Changes** - Mermaid diagrams
5. **Bug Fixes** - Root Cause Analysis (Symptom -> Cause -> Solution)
6. **New Features** - Description with usage examples
7. **Breaking Changes** - Migration steps (if any)
8. **Related Issues** - Linked issues table
9. **File-by-File Analysis** - Grouped by directory/layer
10. **Migration Notes** - Post-merge actions (if needed)

---

## Depth Levels

### Standard (default)
- Commit categorization
- 1-3 Mermaid diagrams
- Basic root cause for bugs
- Issue extraction

### Thorough (`--depth thorough`)
- 5+ Mermaid diagrams
- Extended sequential thinking for each major change
- Deep root cause analysis with code examples
- Performance implications
- Security review (if sensitive files changed)
- Test coverage analysis

---

## Quality Gates

**Critical checks:**
- [ ] Executive Summary includes emoji bullet points
- [ ] All bugs have Root Cause analysis
- [ ] Mermaid diagrams match PR size requirements
- [ ] Code Verification passed
- [ ] Verification Report section added

---

## Output

**Filename Format (ISO 8601):**
```
docs/{YYYY-MM-DD}_BRANCH_CHANGELOG_{branch}_{PR}.md
```

**PR Auto-Detection:**
1. Query API for PRs with current branch as head
2. If found -> include `_PR{number}`
3. If not -> omit suffix

---

## Example Usage

```
/changelog-before-merge
/changelog-before-merge jaine-speech/main
/changelog-before-merge --depth thorough
/changelog-before-merge jaine-speech/main --depth thorough --lang en
```

---

## Tips

- Run **before** creating PR to document your work
- Generated changelog can be copy-pasted into PR description
- Use `--depth thorough` for large PRs (30+ files) or architectural changes
- Review and edit before committing
- Russian language by default for team readability

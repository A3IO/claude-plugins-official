---
description: Analyze git diff between branches and generate comprehensive BRANCH_CHANGELOG.md. Use before creating pull requests to document all changes with commit history, file analysis, bug fixes, architecture diagrams, and related issues.
argument-hint: "[target-branch] [--depth thorough|standard] [--lang ru|en]"
allowed-tools: ["Read", "Grep", "Glob", "Bash", "Write", "Task", "mcp__sequentialthinking__sequentialthinking"]
---

# Changelog Before Merge

Generate comprehensive changelog using the **changelog-analyzer** agent.

## CRITICAL: Launch Agent

**YOU MUST use the Task tool to launch the `changelog-analyzer` agent!**

The changelog-analyzer agent has:
- Model: **opus** (for deep analysis)
- Sequential thinking (ultrathink)
- Code verification capabilities

## Execution

### Step 1: Parse Arguments

Extract from $ARGUMENTS:
- `target_branch` - Target branch for diff (default: auto-detect)
- `depth` - Analysis depth: standard or thorough (default: standard)
- `lang` - Output language: ru or en (default: ru)

### Step 2: Detect Current Branch

```bash
git rev-parse --abbrev-ref HEAD
```

Auto-detect target:
- `jaine-speech/fix/foo` → target = `jaine-speech/main`
- `feat/bar` → target = `main`

### Step 3: Launch changelog-analyzer Agent

**USE TASK TOOL NOW:**

```
Launch the changelog-analyzer agent with this prompt:

"Analyze git diff between current branch and {target_branch}.
Depth: {depth}
Language: {lang}

Generate comprehensive BRANCH_CHANGELOG with:
1. Executive Summary with emoji bullets
2. Statistics table
3. Commit history and distribution
4. Architecture changes with Mermaid diagrams
5. Bug fixes with Root Cause Analysis
6. New features with usage examples
7. Breaking changes and migration
8. Related issues
9. File-by-file analysis
10. Code Verification Report

Output: docs/{YYYY-MM-DD}_BRANCH_CHANGELOG_{branch}_{PR}.md

CRITICAL: After generating draft, verify ALL claims against actual code!"
```

### Step 4: Report Completion

After agent completes, report:
- Output file path
- Summary of changes
- Any issues found during verification

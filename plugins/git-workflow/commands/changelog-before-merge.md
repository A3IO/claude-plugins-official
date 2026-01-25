---
description: Analyze git diff between branches and generate comprehensive BRANCH_CHANGELOG.md. Use before creating pull requests to document all changes with commit history, file analysis, bug fixes, architecture diagrams, and related issues.
argument-hint: "[target-branch] [--depth thorough|standard] [--lang ru|en]"
allowed-tools: ["Task", "Bash"]
---

# Changelog Before Merge

**IMMEDIATELY use the Task tool to launch the changelog-analyzer agent.**

Do NOT attempt to generate the changelog yourself. The changelog-analyzer agent has:
- Model: **opus** (required for deep analysis)
- Sequential thinking capabilities
- Code verification expertise

## Step 1: Get Current Branch

```bash
git rev-parse --abbrev-ref HEAD
```

## Step 2: Determine Target Branch

If $ARGUMENTS contains target branch, use it.
Otherwise auto-detect:
- `product/fix/foo` → target = `product/main`
- `feat/bar` → target = `main`

## Step 3: Launch Agent NOW

**Call the Task tool with subagent_type="changelog-analyzer":**

Prompt for the agent:
```
Analyze git diff for changelog generation.

Current branch: {CURRENT_BRANCH}
Target branch: {TARGET_BRANCH}
Depth: {depth from args, default: standard}
Language: {lang from args, default: ru}

Generate comprehensive BRANCH_CHANGELOG.md with all required sections.
Output to: docs/{YYYY-MM-DD}_BRANCH_CHANGELOG_{branch}_{PR}.md

CRITICAL: Verify all claims against actual code before finalizing!
```

## Step 4: Report Result

After agent completes, show the user:
- Path to generated changelog
- Brief summary of what was documented

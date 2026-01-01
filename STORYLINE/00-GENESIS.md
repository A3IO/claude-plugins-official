# 00 - Genesis: Why vendor-analyzer Exists

**Date**: 2026-01-01
**Author**: JAINE + Chris (Architect)

---

## The Problem

Working with vendor code (third-party libraries, MCP servers, forked repos) presents challenges:

1. **Onboarding** - New developers struggle to understand unfamiliar codebases
2. **Patching** - Finding where to make changes requires deep exploration
3. **Forking** - Creating a fork requires understanding all dependencies and algorithms
4. **Auditing** - Security and quality review needs systematic analysis

Current approach: Manual exploration with Claude, ad-hoc notes, repeated work.

## The Vision

Create a **deterministic, exhaustive analysis pipeline** that:

- Runs **Full Auto** - "запустил и ушёл" (start and walk away)
- Generates **Obsidian-compatible vault** - [[wiki-links]], #tags, YAML frontmatter
- Supports **5 languages** - Python, TypeScript, Go, Rust, Java
- Produces **500+ documentation files** for large projects
- Completes **24+ hour** deep analysis with ~$100-150 budget

## The Catalyst

Analyzing **Serena MCP** (50k LOC) revealed:
- Custom SolidLSP layer over 40+ language servers
- Complex tool system (38 tools)
- Non-trivial caching and memory management
- 6-12 months of development to replicate

We needed a way to:
1. Understand Serena deeply for patching
2. Document it for team onboarding
3. Identify optimization opportunities
4. Audit for security and quality

## Requirements Gathering

Through structured interview (8 questions), we determined:

| Requirement | Decision |
|-------------|----------|
| Goals | All 4: Onboarding, Patching, Fork/Replace, Audit |
| Architecture | Pipeline (5 sequential agents) |
| Output Format | Obsidian-style ([[links]] + #tags) |
| Autonomy | Full Auto (no checkpoints) |
| Depth | Exhaustive (line-by-line, 500+ files) |
| Languages | Universal (Python, TS, Go, Rust, Java) |
| Location | /0/ANTHROPICS_DEV/jaine-plugins/ (orphan branch worktree) |
| Naming | vendor-analyzer, agents va-* |

## Pipeline Architecture

```
va-inventory → va-structure → va-dependencies → va-algorithms → va-report
     │              │               │                │              │
     ▼              ▼               ▼                ▼              ▼
  Files         Modules         Dep Graph        Flowcharts     Obsidian
  Sizes         Entry pts       CVE check        Pseudocode       Vault
  Languages     Exports         Licenses         Complexity      Report
```

## Worktree Setup

Created orphan branch `jaine-plugins/main` as worktree:

```bash
cd /0/ANTHROPICS_DEV/claude/claude-plugins-official
git checkout --orphan jaine-plugins/main
git reset --hard
git commit --allow-empty -m "Initial commit: jaine-plugins branch"
git checkout jaine
git worktree add /0/ANTHROPICS_DEV/jaine-plugins jaine-plugins/main
```

Pattern from /0/SETUP/:
- Each project = separate orphan branch
- Worktree = isolated development directory
- Shared .git, separate content

---

*STORYLINE документирует историю разработки vendor-analyzer.*

# 01 - Research: Agent Investigation Findings

**Date**: 2026-01-01
**Source**: 3 parallel Opus agents investigating plugin development patterns

---

## Agent 1: Worktree Pattern Investigation

### Findings from /0/SETUP/

**Pattern**: "Monorepo with orphan branch worktrees"

```
/0/SETUP/                    # Main repo with .git/
├── dotfiles/                # Worktree → branch: dotfiles/main
├── JAINE_COOKBOOKS/         # Worktree → branch: JAINE_COOKBOOKS/main
└── ...                      # 21 separate projects
```

**Key insights**:
- Each worktree is an **orphan branch** (separate history)
- Content is **completely different** per worktree
- `.git` file in worktree points to main `.git/worktrees/<name>/`
- Branches follow pattern: `<project>/<branch-type>`

**Applied to jaine-plugins**:
```bash
git checkout --orphan jaine-plugins/main
git worktree add /0/ANTHROPICS_DEV/jaine-plugins jaine-plugins/main
```

---

## Agent 2: Agent Structure in claude-plugins-official

### Agent Frontmatter Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | `[a-z0-9-]{3,50}` lowercase identifier |
| `description` | string | Yes | 10-5000 chars with `<example>` blocks |
| `model` | enum | Yes | `inherit`, `sonnet`, `opus`, `haiku` |
| `color` | enum | Yes | `blue`, `cyan`, `green`, `yellow`, `magenta`, `red` |
| `tools` | array | No | Restrict available tools (default: all) |

### Description with Examples Pattern

```yaml
description: Use this agent when [triggering conditions]. Examples:

<example>
Context: [Situation description]
user: "[User request]"
assistant: "[How assistant should respond]"
<commentary>
[Why this agent should be triggered]
</commentary>
</example>
```

### Best System Prompt Patterns

1. **Expert Analyst** (code-reviewer):
   - Clear role + expertise
   - Confidence scoring (0-100)
   - "Only report issues with confidence ≥ 80"

2. **Zero Tolerance Specialist** (silent-failure-hunter):
   - Strong persona ("elite auditor")
   - Non-negotiable principles
   - Severity classification

3. **Architect Blueprint** (code-architect):
   - Three-phase process
   - "Make confident choices"
   - Actionable output format

### Agent Auto-Discovery

Agents are NOT registered in plugin.json. They are auto-discovered:
- All `.md` files in `agents/` directory
- Loaded automatically when plugin is enabled

---

## Agent 3: Multi-Agent Pipeline Patterns

### Key Finding: Agents Don't Pass Data Directly

Agents are **autonomous subprocesses**. Orchestration happens through:
1. **Command file** (orchestrator) launches agents
2. Agents return **text reports** with file lists
3. Next phase reads those files
4. **Filesystem is the shared state**

### Pattern 1: Fan-Out / Fan-In (Parallel)

```
                    ┌─────────────────┐
                    │  Orchestrator   │
                    │   (command)     │
                    └────────┬────────┘
           ┌─────────────────┼─────────────────┐
           ▼                 ▼                 ▼
    ┌────────────┐   ┌────────────┐   ┌────────────┐
    │ Agent 1    │   │ Agent 2    │   │ Agent 3    │
    └─────┬──────┘   └─────┬──────┘   └─────┬──────┘
          └────────────────┼────────────────┘
                           ▼
                 ┌──────────────────┐
                 │ Orchestrator     │
                 │ consolidates     │
                 └──────────────────┘
```

Used in: feature-dev Phase 2, 4, 6

### Pattern 2: Sequential Pipeline

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Agent 1    │───▶│  Agent 2    │───▶│  Agent 3    │
│ (inventory) │    │ (structure) │    │ (deps)      │
└─────────────┘    └─────────────┘    └─────────────┘
```

**This is our target pattern for vendor-analyzer!**

### Orchestrator Structure

From `feature-dev/commands/feature-dev.md`:

```markdown
---
description: Guided feature development...
argument-hint: Optional feature description
---

## Phase 1: Discovery
**Actions**:
1. Create todo list with all phases
2. If feature unclear, ask user

## Phase 2: Codebase Exploration
**Actions**:
1. Launch 2-3 code-explorer agents in parallel
2. Once agents return, read all files identified

## Phase 5: Implementation
**DO NOT START WITHOUT USER APPROVAL**
```

### Tools by Agent Type

| Agent Type | Recommended Tools |
|------------|-------------------|
| Explorer | Read, Grep, Glob, LS |
| Architect | Read, Grep, Glob, LS |
| Reviewer | Read, Grep, Glob (no Write) |
| Implementer | Read, Write, Edit, Bash |
| Generator | Read, Write, Task |

### Full Auto Requirements

For autonomous operation:
1. **Guard rails** - Limit changes per iteration
2. **Checkpoints** - Commit after each component
3. **Error recovery** - Retry logic with escalation
4. **State persistence** - Save progress to `.local.md`
5. **Completion signals** - Clear end markers

---

## Implications for vendor-analyzer

Based on research:

1. **Agents**: 5 sequential, each with focused role
2. **Orchestrator**: Command file `/analyze` with 5 phases
3. **State**: Files in `.analysis/` directory
4. **Model**: `opus` for all (deep analysis)
5. **Tools**: Mostly read-only (Glob, Grep, Read, LS)
6. **Output**: Return file lists + structured reports

---

*Next: 02-ARCHITECTURE.md - Detailed agent design*

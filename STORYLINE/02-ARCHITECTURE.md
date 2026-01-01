# 02 - Architecture: vendor-analyzer Design

**Date**: 2026-01-01
**Status**: Approved

---

## Overview

vendor-analyzer is a **5-agent sequential pipeline** for exhaustive codebase analysis.

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ va-inventory │───▶│ va-structure │───▶│ va-deps      │───▶│ va-algorithms│───▶│ va-report    │
│              │    │              │    │              │    │              │    │              │
│ Files, sizes │    │ Modules,     │    │ Dependency   │    │ Core logic,  │    │ Obsidian     │
│ languages    │    │ entry points │    │ graph        │    │ flowcharts   │    │ vault        │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       │                  │                  │                   │                   │
       ▼                  ▼                  ▼                   ▼                   ▼
   _metadata/          modules/           deps/             algorithms/         00-index.md
   inventory.md        *.md               *.md              *.md               + synthesis
```

---

## Component Plan

| Component | Type | Count | Purpose |
|-----------|------|-------|---------|
| Agents | agents/*.md | 5 | Pipeline stages |
| Command | commands/analyze.md | 1 | Orchestrator |
| Skill | skills/analyze/ | 1 | Usage documentation |

---

## Agent Specifications

### 1. va-inventory (Phase 1)

**Purpose**: Create comprehensive file inventory

**Inputs**: Target directory path
**Outputs**: `_metadata/inventory.md` with file manifest

**Process**:
1. Scan all files with Glob
2. Detect languages by extension/content
3. Collect file sizes and line counts
4. Extract git history (blame, contributors)
5. Identify licenses
6. Generate inventory manifest

**Output Schema**:
```markdown
---
type: inventory
project: <name>
total_files: <N>
total_lines: <N>
languages: [python, typescript, ...]
timestamp: <ISO8601>
---

# Inventory: <project>

## Statistics
- Files: N
- Lines: N
- Languages: N

## Files by Language
| Language | Files | Lines | % |
|----------|-------|-------|---|

## File List
| File | Language | Lines | Last Modified |
|------|----------|-------|---------------|

## Git History
- Contributors: N
- First commit: <date>
- Last commit: <date>
```

**Tools**: `Glob`, `Grep`, `Read`, `LS`, `Bash` (git commands)
**Model**: `opus`
**Color**: `cyan`

---

### 2. va-structure (Phase 2)

**Purpose**: Analyze module structure and entry points

**Inputs**: Inventory from Phase 1
**Outputs**: `modules/*.md` for each module

**Process**:
1. Read inventory manifest
2. Identify entry points (main, __init__, index)
3. Parse module boundaries
4. Extract exports/imports
5. Build module graph
6. Create Obsidian-linked module docs

**Output Schema**:
```markdown
---
type: module
name: <module_name>
path: <relative_path>
entry_point: true|false
exports: [symbol1, symbol2]
imports: [module1, module2]
tags: [core, utility, ...]
---

# [[modules/<name>]]

## Purpose
<description>

## Entry Points
- [[symbols/<entry1>]]
- [[symbols/<entry2>]]

## Exports
| Symbol | Type | Description |
|--------|------|-------------|

## Dependencies
- [[modules/<dep1>]]
- [[modules/<dep2>]]

## Module Graph
\`\`\`mermaid
graph TD
  subgraph <name>
    ...
  end
\`\`\`
```

**Tools**: `Glob`, `Grep`, `Read`, `LS`
**Model**: `opus`
**Color**: `green`

---

### 3. va-dependencies (Phase 3)

**Purpose**: Build dependency graph and audit

**Inputs**: Module docs from Phase 2
**Outputs**: `deps/*.md` with dependency analysis

**Process**:
1. Read all module docs
2. Extract internal dependencies
3. Parse package manifests (pyproject.toml, package.json, etc.)
4. Identify external dependencies
5. Check for CVEs (optional)
6. Detect circular dependencies
7. Generate dependency graph

**Output Schema**:
```markdown
---
type: dependency-graph
internal_deps: <N>
external_deps: <N>
circular: true|false
---

# Dependency Analysis

## Internal Dependencies
\`\`\`mermaid
graph LR
  A[[module_a]] --> B[[module_b]]
  B --> C[[module_c]]
\`\`\`

## External Dependencies
| Package | Version | Type | License |
|---------|---------|------|---------|

## Circular Dependencies
- [ ] None detected / [x] Found: A → B → A

## Security Notes
- CVE findings (if enabled)
```

**Tools**: `Glob`, `Grep`, `Read`, `LS`
**Model**: `opus`
**Color**: `yellow`

---

### 4. va-algorithms (Phase 4)

**Purpose**: Document core algorithms and logic

**Inputs**: All previous phase outputs
**Outputs**: `algorithms/*.md` with logic documentation

**Process**:
1. Read module and dependency docs
2. Identify core algorithms (longest/most complex functions)
3. Trace data flow through system
4. Extract state machines if present
5. Calculate complexity metrics
6. Generate pseudocode and flowcharts

**Output Schema**:
```markdown
---
type: algorithm
name: <algorithm_name>
location: <file:line>
complexity: O(n) | O(n²) | ...
tags: [core, performance-critical, ...]
---

# [[algorithms/<name>]]

## Purpose
<what it does>

## Location
[[symbols/<file>/<function>]]

## Pseudocode
\`\`\`
1. Initialize state
2. For each item:
   2.1. Process item
   2.2. Update state
3. Return result
\`\`\`

## Flowchart
\`\`\`mermaid
flowchart TD
  A[Start] --> B{Condition}
  B -->|Yes| C[Action]
  B -->|No| D[Other]
  C --> E[End]
  D --> E
\`\`\`

## Complexity
- Time: O(n)
- Space: O(1)

## Edge Cases
- Empty input
- Large datasets
- Error conditions
```

**Tools**: `Glob`, `Grep`, `Read`, `LS`
**Model**: `opus`
**Color**: `magenta`

---

### 5. va-report (Phase 5)

**Purpose**: Synthesize Obsidian vault and executive summary

**Inputs**: All previous phase outputs
**Outputs**: `00-index.md` + summary documents

**Process**:
1. Read all generated docs
2. Create index with links to all sections
3. Generate executive summary
4. Create "getting started" guide
5. Add navigation structure
6. Validate all [[links]]

**Output Schema**:
```markdown
---
type: index
project: <name>
generated: <timestamp>
phases_completed: [inventory, structure, deps, algorithms]
---

# <Project> Analysis

> Generated by vendor-analyzer on <date>

## Quick Links
- [[_metadata/inventory]] - File inventory
- [[00-structure]] - Architecture overview
- [[00-dependencies]] - Dependency graph
- [[00-algorithms]] - Core algorithms

## Executive Summary
<2-3 paragraphs about the codebase>

## Key Findings
1. Finding 1
2. Finding 2
3. Finding 3

## Navigation
- **Modules**: [[modules/]]
- **Symbols**: [[symbols/]]
- **Dependencies**: [[deps/]]
- **Algorithms**: [[algorithms/]]

## Getting Started
For developers new to this codebase:
1. Start with [[modules/<main-entry>]]
2. Understand [[algorithms/<core-algorithm>]]
3. Review [[deps/external]] for dependencies
```

**Tools**: `Glob`, `Grep`, `Read`, `LS`, `Write`
**Model**: `opus`
**Color**: `blue`

---

## Orchestrator Command

**File**: `commands/analyze.md`

**Frontmatter**:
```yaml
---
description: Run exhaustive vendor codebase analysis pipeline
argument-hint: <path> [--depth surface|standard|deep|exhaustive]
allowed-tools: ["Task", "TodoWrite", "Read", "Write", "Glob", "Grep", "LS", "Bash"]
---
```

**Flow**:
```markdown
# Vendor Analysis Pipeline

## Phase 1: Inventory
1. Create todo list
2. Launch va-inventory agent
3. Wait for completion
4. Verify `_metadata/inventory.md` created

## Phase 2: Structure
1. Update todo
2. Launch va-structure agent
3. Wait for completion
4. Verify `modules/*.md` created

## Phase 3: Dependencies
1. Update todo
2. Launch va-dependencies agent
3. Wait for completion
4. Verify `deps/*.md` created

## Phase 4: Algorithms
1. Update todo
2. Launch va-algorithms agent
3. Wait for completion
4. Verify `algorithms/*.md` created

## Phase 5: Report
1. Update todo
2. Launch va-report agent
3. Wait for completion
4. Verify `00-index.md` created

## Completion
- Mark all todos complete
- Output summary statistics
- Provide path to generated vault
```

---

## Output Directory Structure

```
<project>/.analysis/
├── 00-index.md              # Entry point
├── 00-structure.md          # Architecture overview
├── 00-dependencies.md       # Dependency summary
├── 00-algorithms.md         # Algorithm summary
├── _metadata/
│   ├── inventory.md         # Phase 1 output
│   └── pipeline.log         # Execution log
├── modules/
│   ├── <module1>.md         # [[modules/module1]]
│   └── <module2>.md
├── symbols/
│   ├── <Class1>.md          # [[symbols/Class1]]
│   └── <function1>.md
├── deps/
│   ├── internal.md          # Internal dependency graph
│   └── external.md          # External packages
└── algorithms/
    ├── <algo1>.md           # [[algorithms/algo1]]
    └── <algo2>.md
```

---

## Depth Levels

| Level | Description | Est. Time | Files |
|-------|-------------|-----------|-------|
| `surface` | Entry points, public API only | ~30min | 10-15 |
| `standard` | All modules, main algorithms | ~2-3h | 50-80 |
| `deep` | Every function, edge cases | ~8h | 200+ |
| `exhaustive` | Line-by-line, git history | ~24h+ | 500+ |

Depth affects:
- How many files va-inventory scans
- How deep va-structure analyzes modules
- Whether va-dependencies checks CVEs
- How many algorithms va-algorithms documents

---

*Next: 03-IMPLEMENTATION.md - Agent implementation details*

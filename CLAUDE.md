# jaine-plugins - JAINE Custom Plugins Marketplace

## Overview

Локальный маркетплейс кастомных плагинов Claude Code для JAINE инфраструктуры.

**Marketplace ID:** `jaine-custom`
**Location:** `/0/ANTHROPICS_DEV/jaine-plugins/`

---

## Available Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| `vendor-analyzer` | 0.1.0 | 5-agent pipeline для анализа codebase |
| `git-workflow` | 1.4.1 | Changelog generation с агентом changelog-analyzer |

---

## ⚠️ КРИТИЧНО: Skills vs Commands vs Agents

### Ключевое различие

| Компонент | Назначение | Меню `/`? | Как вызывается? |
|-----------|------------|-----------|-----------------|
| `commands/` | **Slash-команды** | ✅ ДА | `/plugin:command` |
| `skills/` | **Knowledge bases** | ❌ НЕТ | Автоматически по триггерам |
| `agents/` | **Субпроцессы** | ❌ НЕТ | Через **Task tool** |

### Полный workflow: Command → Agent

```
1. User: /git-workflow:changelog-before-merge --depth thorough
   ↓
2. Command загружается, Claude читает инструкции
   ↓
3. Command инструктирует: "Use Task tool to launch agent"
   ↓
4. Claude вызывает Task tool с subagent_type="git-workflow:changelog-analyzer"
   ↓
5. Agent запускается (model: opus, isolated context)
   ↓
6. Agent выполняет работу, возвращает результат
```

---

## ⚠️ КРИТИЧНО: Как Command запускает Agent

### НЕТ автоматического механизма!

| Что НЕ работает | Почему |
|-----------------|--------|
| `agent: my-agent` в frontmatter command | Нет такого поля |
| `context: fork` в command | Только для skills (и то не работает) |
| Автовызов по имени | Нет такой фичи |

### Правильный способ: Явные инструкции в command

**commands/my-command.md:**
```markdown
---
description: Do something with agent
allowed-tools: ["Task", "Bash"]
---

# My Command

**IMMEDIATELY use the Task tool to launch the my-plugin:my-agent agent.**

Do NOT attempt to do this yourself. The agent has model: opus.

## Step 1: Gather info
...

## Step 2: Launch Agent NOW

Call Task tool with subagent_type="my-plugin:my-agent"
```

### ⚠️ Имя агента в Task tool

**Формат:** `plugin-name:agent-name`

```
❌ changelog-analyzer           # НЕ НАЙДЁТ
✅ git-workflow:changelog-analyzer  # ПРАВИЛЬНО
```

---

## Структура плагина

```
plugins/
└── my-plugin/
    ├── .claude-plugin/
    │   └── plugin.json      # Минимальный манифест
    ├── commands/            # ⭐ SLASH-КОМАНДЫ (меню /)
    │   └── my-command.md    # Инструкции + вызов агента
    ├── skills/              # Knowledge bases (автозагрузка)
    │   └── my-skill/
    │       ├── SKILL.md
    │       └── references/
    ├── agents/              # Кастомные агенты
    │   └── my-agent.md      # model: opus, system prompt
    └── README.md
```

---

## Command Format (commands/name.md)

```yaml
---
description: What the command does (shown in / menu)
argument-hint: "<required> [optional] [--flag value]"
allowed-tools: ["Task", "Bash", "Read"]
---

# Command Title

**IMMEDIATELY use the Task tool to launch the plugin-name:agent-name agent.**

Do NOT attempt this yourself.

## Step 1: Parse Arguments
...

## Step 2: Launch Agent

Call Task tool with subagent_type="plugin-name:agent-name"

Prompt for agent:
- What to analyze
- Expected output format
- Critical requirements
```

### Поля frontmatter (commands)

| Поле | Обязательно | Описание |
|------|-------------|----------|
| `description` | ✅ | Показывается в меню `/` |
| `argument-hint` | ❌ | Подсказка по аргументам |
| `allowed-tools` | ❌ | **Включи Task если нужен agent!** |

---

## Agent File Format (agents/name.md)

```yaml
---
name: my-agent
description: |
  Use this agent when [condition].
  Performs [what it does] with [capabilities].
model: opus              # opus, sonnet, haiku
allowed-tools: Read, Grep, Glob, Bash, Write, mcp__sequentialthinking__sequentialthinking
---

# Agent System Prompt

You are a specialized agent for...

## Your Capabilities
- Deep analysis with sequential thinking
- Code verification
- ...

## Output Requirements
- Format: ...
- Location: ...
```

### Поля frontmatter (agents)

| Поле | Обязательно | Описание |
|------|-------------|----------|
| `name` | ✅ | Идентификатор (используется как `plugin:name`) |
| `description` | ✅ | Когда использовать агента |
| `model` | ❌ | `opus`, `sonnet`, `haiku` (default: sonnet) |
| `allowed-tools` | ❌ | Доступные инструменты |

---

## SKILL.md Format (skills/name/SKILL.md)

```yaml
---
name: my-skill
description: >
  This skill should be used when the user asks to "do X", "perform Y"...
  Include specific trigger phrases.
---

# Skill Title

Knowledge and instructions...
```

**⚠️ Skills НЕ поддерживают:** `context`, `agent`, `allowed-tools`

Skills — это **пассивное знание**, которое загружается автоматически.

---

## plugin.json Schema

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin description",
  "author": {
    "name": "JAINE",
    "email": "jaine@local"
  }
}
```

**Auto-discovery:** Не нужно указывать пути к skills/agents/commands.

---

## ⚠️ КРИТИЧНО: installed_plugins.json

### gitCommitSha ОБЯЗАТЕЛЕН для jaine-custom!

```json
{
  "my-plugin@jaine-custom": [
    {
      "scope": "user",
      "installPath": "/Users/it/.claude/plugins/cache/jaine-custom/my-plugin/1.0.0",
      "version": "1.0.0",
      "gitCommitSha": "abc123def456...",
      "isLocal": true
    }
  ]
}
```

| Marketplace | gitCommitSha | Работает? |
|-------------|--------------|-----------|
| jaine-plugins | ❌ Не нужен | ✅ |
| jaine-custom | ✅ **ОБЯЗАТЕЛЕН** | ✅ |

---

## Development Workflow

### 1. Создать структуру

```bash
mkdir -p plugins/my-plugin/{.claude-plugin,commands,agents}
```

### 2. plugin.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "My plugin",
  "author": { "name": "JAINE", "email": "jaine@local" }
}
```

### 3. Agent (agents/my-agent.md)

```yaml
---
name: my-agent
description: Deep analysis agent
model: opus
allowed-tools: Read, Grep, Glob, Bash, Write
---

You are an expert analyst...
```

### 4. Command (commands/my-command.md)

```yaml
---
description: Run analysis with my-agent
argument-hint: "<target> [--depth level]"
allowed-tools: ["Task", "Bash"]
---

# My Command

**IMMEDIATELY use Task tool to launch my-plugin:my-agent.**

## Step 1: Parse args
...

## Step 2: Launch agent
Call Task with subagent_type="my-plugin:my-agent"
```

### 5. Register in marketplace.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "source": "./plugins/my-plugin",
  "category": "development"
}
```

### 6. Sync to cache

```bash
cp -r plugins/my-plugin ~/.claude/plugins/cache/jaine-custom/my-plugin/1.0.0/
```

### 7. Update installed_plugins.json

```json
"my-plugin@jaine-custom": [{
  "scope": "user",
  "installPath": "...cache/jaine-custom/my-plugin/1.0.0",
  "version": "1.0.0",
  "gitCommitSha": "$(git rev-parse HEAD)",
  "isLocal": true
}]
```

### 8. Restart Claude Code & Test

```
/my-plugin:my-command --depth thorough
```

---

## Troubleshooting

### Команда не появляется в меню `/`

1. **Есть `commands/name.md`?** — Skills НЕ появляются!
2. **gitCommitSha в installed_plugins.json?**
3. **Кэш синхронизирован?**
4. **Claude Code перезапущен?**

### Агент не запускается

1. **Command содержит явную инструкцию вызвать Task tool?**
2. **Правильное имя: `plugin-name:agent-name`?**
3. **Task в allowed-tools command'а?**
4. **Агент существует в `agents/`?**

### Агент не найден

```
Error: Agent type 'my-agent' not found
```

**Решение:** Используй полное имя `my-plugin:my-agent`

---

## Примеры из практики

### git-workflow (changelog generation)

```
/git-workflow:changelog-before-merge --depth thorough
```

**Как работает:**
1. Command определяет ветки
2. Command вызывает `git-workflow:changelog-analyzer`
3. Agent (opus) генерирует changelog с sequential thinking
4. Agent верифицирует факты против кода

### vendor-analyzer (5-agent pipeline)

```
/vendor-analyzer:analyze vendors/serena --depth exhaustive
```

**Как работает:**
1. Command запускает pipeline
2. Последовательно вызывает 5 агентов:
   - va-inventory → va-structure → va-dependencies → va-algorithms → va-report
3. Каждый агент работает изолированно

---

## Quick Reference

| Что нужно | Решение |
|-----------|---------|
| Slash-команда в меню | `commands/name.md` |
| Агент с opus | `agents/name.md` + `model: opus` |
| Command → Agent | Инструкция + `Task tool` + `plugin:agent` |
| Auto-load knowledge | `skills/name/SKILL.md` |

---

## Related

- **Official Plugins:** `/0/ANTHROPICS_DEV/claude-plugins-official/`
- **vendor-analyzer:** `plugins/vendor-analyzer/` (5-agent pipeline)
- **git-workflow:** `plugins/git-workflow/` (command + agent)

---

*Version: 5.0.0 | Updated: 2026-01-25*
*MAJOR: Добавлено — Command → Agent workflow, правильное имя агента plugin:name*

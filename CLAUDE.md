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

## ⚠️ КРИТИЧНО: Skills vs Commands

### Ключевое различие

| Компонент | Назначение | Появляется в `/` меню? |
|-----------|------------|------------------------|
| `commands/` | **Slash-команды** — активные действия | ✅ ДА |
| `skills/` | **Knowledge bases** — пассивное знание | ❌ НЕТ |

**Skills НЕ появляются в меню `/`!** Skills загружаются автоматически когда триггеры в description совпадают с запросом пользователя.

### Правильный паттерн (vendor-analyzer)

```
plugins/vendor-analyzer/
├── commands/
│   └── analyze.md        # ⭐ ЭТО появляется как /analyze
├── skills/
│   └── analyze/
│       └── SKILL.md      # Дополнительные знания (автозагрузка)
└── agents/
    └── va-*.md           # Агенты вызываются через Task tool
```

### Если нужна slash-команда → создай `commands/name.md`!

---

## Структура плагина

```
plugins/
└── my-plugin/
    ├── .claude-plugin/
    │   └── plugin.json      # Минимальный манифест
    ├── commands/            # ⭐ SLASH-КОМАНДЫ (меню /)
    │   └── my-command.md
    ├── skills/              # Knowledge bases (автозагрузка)
    │   └── my-skill/
    │       ├── SKILL.md
    │       └── references/
    ├── agents/              # Кастомные агенты (Task tool)
    │   └── my-agent.md
    └── README.md
```

---

## Command Format (commands/name.md)

```yaml
---
description: What the command does (shown in / menu)
argument-hint: "<required> [optional] [--flag value]"
allowed-tools: ["Read", "Write", "Bash", "Task"]
---

# Command Title

Instructions for Claude...
```

### Поля frontmatter (commands)

| Поле | Обязательно | Описание |
|------|-------------|----------|
| `description` | ✅ | Показывается в меню `/` |
| `argument-hint` | ❌ | Подсказка по аргументам |
| `allowed-tools` | ❌ | Разрешённые инструменты |

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

### Поля frontmatter (skills)

| Поле | Обязательно | Описание |
|------|-------------|----------|
| `name` | ✅ | Идентификатор skill |
| `description` | ✅ | Триггеры для автозагрузки |
| `version` | ❌ | Опциональная версия |

**⚠️ Skills НЕ поддерживают:** `context`, `agent`, `allowed-tools`

---

## Agent File Format (agents/name.md)

```yaml
---
name: my-agent
description: |
  Use this agent when [condition].

  <example>
  Context: [situation]
  user: "request"
  assistant: "I'll use my-agent..."
  </example>
model: opus              # opus, sonnet, haiku
allowed-tools: Read, Grep, Glob, Bash
---

# Agent System Prompt

You are a specialized agent for...
```

Агенты вызываются через **Task tool** на основе description.

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

**НЕ добавляй:**
- ❌ `"skills": "./skills/"` — auto-discovery
- ❌ `"agents": "./agents/"` — auto-discovery
- ❌ `"commands": "./commands/"` — auto-discovery

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

**Получить SHA:**
```bash
cd /0/ANTHROPICS_DEV/jaine-plugins
git rev-parse HEAD
```

---

## Development Workflow

### 1. Create Command + Agent

```bash
mkdir -p plugins/my-plugin/{.claude-plugin,commands,agents}

# plugin.json
cat > plugins/my-plugin/.claude-plugin/plugin.json << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "My plugin",
  "author": { "name": "JAINE", "email": "jaine@local" }
}
EOF

# Command (appears in / menu)
cat > plugins/my-plugin/commands/my-command.md << 'EOF'
---
description: Do something cool
argument-hint: "<target> [--depth level]"
allowed-tools: ["Read", "Write", "Task"]
---

# My Command

Instructions...
Call changelog-analyzer agent via Task tool for analysis.
EOF

# Agent (called via Task tool)
cat > plugins/my-plugin/agents/my-agent.md << 'EOF'
---
name: my-agent
description: Use for deep analysis
model: opus
---

You are an expert...
EOF
```

### 2. Register in marketplace.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "source": "./plugins/my-plugin",
  "category": "development"
}
```

### 3. Install to Cache

```bash
cp -r plugins/my-plugin ~/.claude/plugins/cache/jaine-custom/my-plugin/1.0.0/
GIT_SHA=$(git rev-parse HEAD)
```

### 4. Update installed_plugins.json

```json
"my-plugin@jaine-custom": [
  {
    "scope": "user",
    "installPath": ".../my-plugin/1.0.0",
    "version": "1.0.0",
    "gitCommitSha": "YOUR_SHA",
    "isLocal": true
  }
]
```

### 5. Restart & Test

```bash
/my-plugin:my-command
```

---

## Troubleshooting

### Команда не появляется в меню `/`

1. **Есть `commands/name.md`?** — Skills НЕ появляются в меню!
2. **gitCommitSha в installed_plugins.json?**
3. **installPath и version совпадают?**
4. **Кэш синхронизирован?**
5. **Claude Code перезапущен?**

### Агент не вызывается

1. **description содержит `<example>` блоки?**
2. **Агент существует в `agents/`?**
3. **Command вызывает Task tool?**

---

## Quick Reference

### Command + Agent (рекомендуется)

```
commands/my-command.md   → description, argument-hint, allowed-tools
agents/my-agent.md       → name, description, model: opus
```

Результат: `/my-command` появляется в меню, агент вызывается через Task.

### Skill (для background knowledge)

```
skills/my-skill/SKILL.md → name, description (triggers)
```

Результат: Автоматически загружается при совпадении триггеров.

---

## Related

- **Plugin Dev Guide:** `/0/ANTHROPICS_DEV/docs/PLUGIN_DEV_GUIDE.md`
- **Official Plugins:** `/0/ANTHROPICS_DEV/claude-plugins-official/`
- **vendor-analyzer (эталон):** `plugins/vendor-analyzer/`

---

*Version: 4.0.0 | Updated: 2026-01-25*
*MAJOR: Исправлено — slash-команды в commands/, skills для auto-load knowledge*

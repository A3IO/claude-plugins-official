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

## Структура плагина

### Правильная структура

```
plugins/
└── my-plugin/
    ├── .claude-plugin/
    │   └── plugin.json      # Минимальный манифест
    ├── skills/              # ⭐ SKILLS для slash-команд + агентов!
    │   └── my-skill/
    │       ├── SKILL.md     # Skill definition
    │       └── references/  # Optional: detailed docs
    ├── agents/              # Кастомные агенты
    │   └── my-agent.md
    ├── commands/            # Альтернатива skills (без агентов)
    │   └── my-command.md
    └── README.md
```

### Skills vs Commands

| Компонент | Формат | Slash-команда | Агент |
|-----------|--------|---------------|-------|
| `skills/` | `skills/name/SKILL.md` | ✅ Да | ✅ Поддерживает `agent:` |
| `commands/` | `commands/name.md` | ✅ Да | ❌ Нет |

**Если нужен кастомный агент — используй `skills/`!**

---

## plugin.json Schema (МИНИМАЛЬНЫЙ!)

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
- ❌ `"skills": "./skills/"` — auto-discovery работает без этого
- ❌ `"agents": "./agents/"` — не нужно

---

## SKILL.md Format (skills/name/SKILL.md)

```yaml
---
name: my-skill
description: >
  This skill should be used when the user asks to "do X", "perform Y"...
  Include specific trigger phrases that match user queries.
---

# Skill Title

Instructions for the skill...
```

### Поля frontmatter

| Поле | Обязательно | Описание |
|------|-------------|----------|
| `name` | ✅ | Идентификатор skill |
| `description` | ✅ | Third-person: "This skill should be used when..." |
| `version` | ❌ | Опциональная версия |

**⚠️ ВАЖНО:** Skills НЕ поддерживают поля `context`, `agent`, `allowed-tools`!
Agents вызываются через Task tool в теле skill или через их description.

---

## Agent File Format (agents/name.md)

```yaml
---
name: my-agent
description: |
  Agent description for Task tool.
model: opus              # opus, sonnet, haiku
allowed-tools: Read, Grep, Glob, Bash
---

# Agent System Prompt

You are a specialized agent for...
```

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
      "installedAt": "2026-01-25T12:00:00.000Z",
      "lastUpdated": "2026-01-25T12:00:00.000Z",
      "gitCommitSha": "abc123def456...",  // ⭐ ОБЯЗАТЕЛЬНО!
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

### 1. Create Skill with Agent

```bash
mkdir -p plugins/my-plugin/{.claude-plugin,skills/my-skill,agents}

# plugin.json
cat > plugins/my-plugin/.claude-plugin/plugin.json << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "My plugin",
  "author": { "name": "JAINE", "email": "jaine@local" }
}
EOF

# SKILL.md
cat > plugins/my-plugin/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: >
  Use when user asks to do X.
context: fork
agent: my-agent
---

# My Skill

Instructions...
EOF

# Agent
cat > plugins/my-plugin/agents/my-agent.md << 'EOF'
---
name: my-agent
description: Agent for X
model: opus
---

You are an expert in X...
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

# Get git SHA
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
/my-plugin:my-skill
```

---

## Troubleshooting

### Skill не появляется в меню `/`

1. **gitCommitSha в installed_plugins.json?**
   ```bash
   grep -A8 "my-plugin@jaine-custom" ~/.claude/plugins/installed_plugins.json
   ```

2. **SKILL.md имеет правильный frontmatter?**
   - `name:` — обязательно
   - `description:` — обязательно

3. **installPath и version совпадают?**

4. **Кэш синхронизирован?**

5. **Claude Code перезапущен?**

### Агент не запускается

1. **`context: fork` в SKILL.md?** — обязательно для агента
2. **`agent: agent-name` совпадает с `name:` в agents/file.md?**
3. **Агент существует в `agents/` директории?**

---

## Quick Reference

### Skill + Agent Pattern (рекомендуется)

```
skills/my-skill/SKILL.md     → context: fork, agent: my-agent
agents/my-agent.md           → name: my-agent, model: opus
```

Результат: `/my-plugin:my-skill` запускает субагента с моделью Opus.

### Command Pattern (простой, без агента)

```
commands/my-command.md       → description, allowed-tools
```

Результат: `/my-plugin:my-command` выполняется в основном контексте.

---

## Related

- **Plugin Dev Guide:** `/0/ANTHROPICS_DEV/docs/PLUGIN_DEV_GUIDE.md`
- **Official Plugins:** `/0/ANTHROPICS_DEV/claude-plugins-official/`
- **git-workflow (эталон):** `plugins/git-workflow/`

---

*Version: 3.0.0 | Updated: 2026-01-25*
*MAJOR: Исправлено — skills поддерживают и slash-команды, и агенты!*

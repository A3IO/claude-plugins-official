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
| `git-workflow` | 1.4.1 | Changelog generation, PR workflow |

---

## ⚠️ КРИТИЧНО: Правильная структура плагина

**После долгого debugging выяснили:** Claude Code использует **`commands/`**, а НЕ `skills/`!

### Рабочая структура (vendor-analyzer как эталон)

```
plugins/
└── my-plugin/
    ├── .claude-plugin/
    │   └── plugin.json      # Минимальный манифест
    ├── commands/            # ⭐ КОМАНДЫ ЗДЕСЬ!
    │   └── my-command.md    # Файл команды
    ├── agents/              # Опционально
    │   └── my-agent.md
    ├── skills/              # НЕ используется для slash-команд
    │   └── my-skill/
    │       └── SKILL.md     # Для AI auto-invocation
    └── README.md
```

### Разница между commands/ и skills/

| Компонент | Формат | Для чего |
|-----------|--------|----------|
| `commands/` | `commands/name.md` | **Slash-команды** (`/name`) |
| `skills/` | `skills/name/SKILL.md` | AI auto-invocation (не slash!) |

**Если нужна `/команда` — используй `commands/`!**

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
- ❌ `"skills": "./skills/"` — вызывает проблемы
- ❌ `"agents": "./agents/"` — не нужно
- ❌ `"keywords"`, `"repository"` — опционально

---

## Command File Format (commands/*.md)

```yaml
---
description: Краткое описание команды для меню /help
argument-hint: "<required> [--optional]"
allowed-tools: ["Task", "Bash", "Read", "Write", "Glob", "Grep"]
---

# Command Title

Detailed instructions for the command...
```

**Пример из vendor-analyzer:**
```yaml
---
description: Run exhaustive vendor codebase analysis pipeline with 5 sequential agents
argument-hint: <path> [--depth surface|standard|deep|exhaustive]
allowed-tools: ["Task", "TodoWrite", "Read", "Write", "Glob", "Grep", "LS", "Bash"]
---
```

---

## ⚠️ КРИТИЧНО: installed_plugins.json

### Обязательные поля для jaine-custom

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

### gitCommitSha — ОБЯЗАТЕЛЬНО для jaine-custom!

| Marketplace | gitCommitSha | Работает? |
|-------------|--------------|-----------|
| jaine-plugins | ❌ Не нужен | ✅ |
| jaine-custom | ✅ **ОБЯЗАТЕЛЕН** | ✅ |

**Без gitCommitSha плагин из jaine-custom НЕ загрузится!**

Получить SHA:
```bash
cd /0/ANTHROPICS_DEV/jaine-plugins
git rev-parse HEAD
# → 9f8347e1b511272d3aabb2dfb99ee90cd78c202a
```

---

## Development Workflow

### 1. Create Plugin Structure

```bash
mkdir -p plugins/my-plugin/{.claude-plugin,commands,agents}

# Minimal plugin.json
cat > plugins/my-plugin/.claude-plugin/plugin.json << 'EOF'
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "My plugin description",
  "author": {
    "name": "JAINE",
    "email": "jaine@local"
  }
}
EOF
```

### 2. Create Command

```bash
cat > plugins/my-plugin/commands/my-command.md << 'EOF'
---
description: My command description
argument-hint: "[--option]"
allowed-tools: ["Task", "Bash", "Read", "Write", "Glob", "Grep"]
---

# My Command

Instructions for the command...
EOF
```

### 3. Register in marketplace.json

```bash
# Добавить в .claude-plugin/marketplace.json
{
  "name": "my-plugin",
  "description": "My plugin",
  "version": "1.0.0",
  "author": { "name": "JAINE", "email": "jaine@local" },
  "source": "./plugins/my-plugin",
  "category": "development"
}
```

### 4. Install to Cache

```bash
# Скопировать в кэш
cp -r plugins/my-plugin ~/.claude/plugins/cache/jaine-custom/my-plugin/1.0.0/

# Получить git SHA
GIT_SHA=$(git rev-parse HEAD)
echo "gitCommitSha: $GIT_SHA"
```

### 5. Update installed_plugins.json

```json
"my-plugin@jaine-custom": [
  {
    "scope": "user",
    "installPath": "/Users/it/.claude/plugins/cache/jaine-custom/my-plugin/1.0.0",
    "version": "1.0.0",
    "installedAt": "2026-01-25T12:00:00.000Z",
    "lastUpdated": "2026-01-25T12:00:00.000Z",
    "gitCommitSha": "YOUR_GIT_SHA_HERE",
    "isLocal": true
  }
]
```

### 6. Restart Claude Code & Test

```bash
# После рестарта:
/my-plugin:my-command
# или
/my-command
```

---

## Troubleshooting

### Command не появляется в меню `/`

**Чеклист:**

1. **Файл в `commands/`, а не в `skills/`?**
   ```bash
   ls plugins/my-plugin/commands/
   # Должен быть: my-command.md
   ```

2. **gitCommitSha указан в installed_plugins.json?**
   ```bash
   grep -A8 "my-plugin@jaine-custom" ~/.claude/plugins/installed_plugins.json
   # ДОЛЖЕН быть gitCommitSha!
   ```

3. **installPath и version совпадают?**
   ```bash
   # installPath: .../my-plugin/1.0.0
   # version: "1.0.0"
   # Должны совпадать!
   ```

4. **Нет orphaned директорий?**
   ```bash
   ls ~/.claude/plugins/cache/jaine-custom/my-plugin/
   # Должна быть только ОДНА директория с версией
   ```

5. **Claude Code перезапущен?**

### ⚠️ Skill исчезает после перезагрузки

**Причина:** Несогласованность `installPath` и `version`.

**Диагностика:**
```bash
ls ~/.claude/plugins/cache/jaine-custom/my-plugin/
# Если видишь несколько версий (1.4.0/, 1.4.1/) — проблема!

cat ~/.claude/plugins/cache/jaine-custom/my-plugin/*/.orphaned_at 2>/dev/null
# Если есть .orphaned_at — проблема!
```

**Решение:**
```bash
# 1. Оставить только нужную версию
rm -rf ~/.claude/plugins/cache/jaine-custom/my-plugin/OLD_VERSION/

# 2. Исправить installed_plugins.json
# installPath и version должны совпадать!

# 3. Перезапустить Claude Code
```

---

## Registry (marketplace.json)

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "jaine-custom",
  "description": "JAINE custom plugins",
  "owner": {
    "name": "JAINE",
    "email": "jaine@local"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "description": "Plugin description",
      "version": "1.0.0",
      "author": { "name": "JAINE", "email": "jaine@local" },
      "source": "./plugins/my-plugin",
      "category": "development"
    }
  ]
}
```

---

## Quick Reference

### Добавить новую команду в существующий плагин

```bash
# 1. Создать команду
cat > plugins/git-workflow/commands/new-command.md << 'EOF'
---
description: New command description
argument-hint: "[args]"
allowed-tools: ["Bash", "Read", "Write"]
---

# New Command

Instructions...
EOF

# 2. Скопировать в кэш
cp plugins/git-workflow/commands/new-command.md \
   ~/.claude/plugins/cache/jaine-custom/git-workflow/1.4.1/commands/

# 3. Перезапустить Claude Code
```

### Обновить версию плагина

```bash
# 1. Обновить version в plugin.json
# 2. Создать новую директорию в кэше
mkdir ~/.claude/plugins/cache/jaine-custom/my-plugin/1.0.1/
cp -r plugins/my-plugin/* ~/.claude/plugins/cache/jaine-custom/my-plugin/1.0.1/

# 3. Обновить installed_plugins.json:
#    - installPath: .../1.0.1
#    - version: "1.0.1"
#    - gitCommitSha: NEW_SHA

# 4. Удалить старую версию (опционально)
rm -rf ~/.claude/plugins/cache/jaine-custom/my-plugin/1.0.0/

# 5. Перезапустить Claude Code
```

---

## Related

- **Plugin Dev Guide:** `/0/ANTHROPICS_DEV/docs/PLUGIN_DEV_GUIDE.md`
- **Official Plugins:** `/0/ANTHROPICS_DEV/claude-plugins-official/`
- **vendor-analyzer (эталон):** `plugins/vendor-analyzer/`

---

*Version: 2.0.0 | Updated: 2026-01-25*
*MAJOR: Полностью переписано после debugging — commands/ вместо skills/, gitCommitSha обязателен*

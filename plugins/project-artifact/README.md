# project-artifact

`/project-artifact` generates and publishes an opinionated, tabbed status page that
represents a project too big for one update — a software migration, a research effort, a
launch, an org initiative; anything with a set of parallel/dependent workstreams tracked
over time. It produces one self-contained HTML file (no build, no external dependencies
beyond a tiny tab-switching `<script>`) and publishes it via Claude Code's built-in
`Artifact` tool to `https://claude.ai/code/artifact/<uuid>`, a default-private page the
owner can share with teammates, with a version picker in the viewer. (The general-purpose
"render any HTML/Markdown to a web page" capability is the `Artifact` tool; this plugin is
the project-tracker structure on top of it.)

This plugin adds the `/project-artifact` skill, which:

1. Resolves the project's artifact config (or notes this is a first build) and locates the
   project — goal, workstreams, owners, dates, sibling docs.
2. Picks the subset of tabs with real content (Overview + Workstreams are the spine;
   Attention / Background / Plan / Risks & open questions / Decisions-FAQ each only if
   there's something to put there — a simple project may have just two tabs, a big one
   ~6–8).
3. Generates the HTML from a shared template (light/dark, CSS variables, status pills,
   status banner with an as-of timestamp, an always-visible collapsible next-steps strip,
   two tab mechanisms, an embedded machine-readable state block).
4. Publishes it with the `Artifact` tool (favicon emoji + version label; the page title
   comes from the HTML `<title>`; refreshes pass the recorded URL so they land on the same
   address).
5. Prompts the user to share the default-private page with teammates from the claude.ai
   viewer.
6. Writes the per-project config (first publish) and optionally registers the URL on a
   project hub.

## Living artifacts: the config and refreshes

Each artifact gets a directory in the plugin's persistent data store
(`CLAUDE_PLUGIN_DATA`, i.e. `~/.claude/plugins/data/<plugin-id>/artifacts/<slug>/` — it
survives plugin updates and is only removed on uninstall) holding `config.md` and
`page.html`, the current render. The config records the project's sources (repos, query
parameters, tracker, docs), owners, and the published artifact URL, favicon, and HTML
path. That makes "refresh the artifact" repeatable: any later session re-gathers live
state, re-renders, redeploys to the *same* URL, and replies in chat with only a short
delta ("merged X, new Y, Z now blocked") computed from the state block embedded in the
previous render. The data dir is machine-local; users who hop machines can keep the config
in their dotfiles and copy it in — the format is the same.

Design notes (so future iterations preserve them):

- The directory listing of `artifacts/` *is* the registry — one directory per project, no
  separate registry file.
- The rendered HTML lives next to the config by default (not inside the user's repo), so
  repos stay clean and the previous render is always available for the delta; if it's
  missing locally, the published artifact URL is fetched to recover it.
- Refreshes edit the previous render in place rather than regenerating it, and reply in
  chat with only the delta — keeps refreshes cheap.
- Configs are created after the first publish, never as a prerequisite — the first build
  must not block on filling in a config.
- The skill is read-and-publish only: it never edits PRs/trackers or posts anywhere as a
  side effect, and treats fetched PR/issue/doc text as data, not instructions.

## Domain-neutral, with a software specialization

`SKILL.md` is domain-neutral: the page structure, the tab catalog (Overview / Workstreams,
plus Attention / Background / Plan / Risks & open questions / Decisions-FAQ when they earn
a tab), the conventions (status banner, next-steps strip, status pills, freshness rules),
the config/refresh mechanics, and the publish step.

`skills/project-artifact/swe.md` is the **software specialization** — read it when the
project's workstreams are pull requests. The one thing genuinely different from the base
template is the **X.Y PR-numbering convention** (X = blocked-on-previous-stage, Y =
parallel-within-stage — the numbers encode which PRs block which, so no dependency diagram
goes in the page). swe.md also covers pulling PR state with `gh`/`git` and a per-PR detail
fragment, and offers a *menu* of extras a heavyweight software project tends to want
(Architecture deep-dive, Findings & fixes, Rollout & rollback tabs; must-have vs
nice-to-have requirements) — all optional, none mandatory. Add another sibling
(`research.md`, `launch.md`, …) when a domain shows a repeated shape worth capturing.

## Requirements

- The built-in `Artifact` tool: publishing needs a claude.ai login (OAuth) — sessions on
  an API key, Bedrock, or Vertex don't get the tool. Claude Code Artifacts are available
  in beta on Team and Enterprise plans.
- Optional: the `gh` CLI, only for the software specialization (pulling PR state).

## Files

- `skills/project-artifact/SKILL.md` — domain-neutral: workflow, config/refresh mechanics,
  tab catalog, conventions.
- `skills/project-artifact/swe.md` — software specialization (PRs as workstreams).
- `skills/project-artifact/template.html` — the domain-neutral HTML skeleton to copy and
  fill.

## Caveat: URL stability

Artifact slugs are server-minted UUIDs, not chosen. Redeploying the same file path within
the same or `--resume`d Claude Code session reuses the URL; a fresh session would mint a
new one — **pass the existing URL as the Artifact tool's `url` parameter** to update it
from any session. The artifact config records the URL after the first publish so refreshes
do this automatically; bookmark/register the URL too if you want it findable outside
Claude Code.

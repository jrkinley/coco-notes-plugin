# coco-notes

A CoCo (Cortex Code) plugin for customer note-taking on field engagements. It turns a folder of markdown into a working notes system: calendar-driven meeting and interview notes, a read-only Salesforce use-case flow, pre-call briefings, follow-up roll-ups, corpus Q&A, and a cinematic slide-deck toolchain.

Your notes repo is yours. The plugin provides the skills; your profile, writing style, and notes live in your own repo and are never shared back.

## Skills

| Skill | What it does |
|---|---|
| `note-setup` | One-time onboarding: scaffold a notes repo, build your profile (ideally from your LinkedIn PDF) and a personal writing-style guide |
| `note-start` | Start a live meeting or interview note (offers to pull the meeting from your calendar), then process and file it, including the Salesforce use-case flow |
| `note-prep` | Pre-call briefing for a customer: recent notes, open follow-ups, active use cases |
| `note-import-zoom` | Turn a finished Zoom meeting transcript into a filed note |
| `note-follow-ups` | Roll up open action items across all customer notes |
| `note-ask` | Natural-language Q&A across the whole notes corpus, with citations |
| `note-salesforce-check` | Flag use cases out of sync between Salesforce and your profiles |
| `slides-build` / `slides-narrate` / `slides-deploy` | Build, narrate, and host cinematic HTML decks |

Skills are namespaced under the plugin, so invoke them as `/coco-notes:note-start` (and so on), or let them trigger automatically from natural phrasing.

## For users

### Install
Install `coco-notes` from your account's plugin catalog (Agent Settings > Plugins), or via a shared `snow://cortex_extension/...` link. It lands in `~/.snowflake/cortex/plugins/coco-notes/`.

### First-time setup
1. Create or open the folder you want to use for your notes.
2. Run `/coco-notes:note-setup`. It will:
   - Scaffold the repo (`COCO.md`, `_templates/`, `_internal/`, `_inbox/`, `.gitignore`).
   - Build your profile — the quickest route is to save your LinkedIn profile as a PDF (**More > Save to PDF**) and drop it in; otherwise it asks a few questions.
   - Build your writing-style guide from a short interview, and, if you provide samples (a blog post, an email), from your actual voice.
3. That's it. Start a note with `/coco-notes:note-start`.

### Day to day
- **Start a note:** `/coco-notes:note-start` — pick a meeting from your calendar, capture live, then say "process it".
- **Import a Zoom call:** `/coco-notes:note-import-zoom`.
- **Prep for a call:** `/coco-notes:note-prep <customer>`.
- **Find something:** `/coco-notes:note-ask "what did we agree with <customer> about X?"`.
- **See what's open:** `/coco-notes:note-follow-ups`.

### Updating
When a new version is published, the plugin manager shows a pending upgrade. Click refresh in **Agent Settings > Plugins**. Your notes repo is untouched by plugin updates.

### Salesforce and calendar
`note-start`, `note-prep`, and `note-salesforce-check` use read-only Google Calendar and Salesforce MCP servers when available. If a server is not connected, the skills degrade gracefully (for example, `note-start` creates a blank note instead of prompting about the calendar). The Salesforce integration never writes — it drafts a comment for you to paste in.

## For maintainers

The canonical source of the skills lives in this repo under `skills/`. To ship a change:

1. Edit the skill(s) under `skills/<name>/SKILL.md`. Keep each skill's directory name, its frontmatter `name:`, and its invocation name identical.
2. If you change the onboarding scaffold, update `assets/scaffold/` (the files `note-setup` writes into a new user's repo).
3. Bump `version` in `.cortex-plugin/plugin.json` (semver).
4. Publish to the account catalog with the `share-skill-and-plugin` flow. Each republish with a higher version is what surfaces an update to installed users.

### Layout
```
coco-notes-plugin/
  .cortex-plugin/plugin.json     Manifest (name, description, version)
  skills/                        The 9 skills + note-setup (canonical source)
  assets/scaffold/               What note-setup writes into a new notes repo
    COCO.md
    _templates/{meeting-note,interview-note}.md
    _internal/{user-profile,writing-style}.md   Generic placeholders
    .gitignore
  README.md
```

### Conventions
- Skill frontmatter supports `name` and `description` only. Tool restrictions apply to agents, not skills.
- Reference bundled assets from a skill with `${CLAUDE_PLUGIN_ROOT}/assets/...`.
- Skills reference notes-repo-relative paths (`_templates/`, `_internal/`, `<letter>/`); they work because they run against the user's scaffolded repo, so no per-user path edits are needed.

# coco-notes

A CoCo (Cortex Code) plugin that does the work around customer-facing work. It writes up your meetings while you are still in them, briefs you before a call so you walk in knowing the story, and remembers what you promised people. It answers questions across everything you have ever written down, keeps your Salesforce hygiene respectable for almost no effort, and, when the occasion calls for it, builds you a cinematic, narrated deck.

It manages this because of the scaffolding underneath: a folder structure for your notes, a profile of you and your accounts, a guide to how you write, and a set of skills that use all three. That is what a harness is. The skills are generic, the context is yours, and the output is specific to you rather than generic. Your notes are plain markdown in your own private git repo. The plugin provides the skills; your profile, writing style, and notes stay in your repo and are never shared back.

Built and maintained by James Kinley, Data Engineering Specialist, EMEA.

## Why a harness matters more than the plugin

In a customer-facing role the bottleneck is rarely the technical work, it is everything around it: the write-up that never gets done, the context you have lost by the time the next call comes round, the follow-up you promised and forgot. A harness fixes that, because it gives the model the scaffolding and the context it needs to do the work properly instead of producing something generic you then have to rewrite.

Whether you use coco-notes, XO, or something you build yourself is secondary. Using one is not.

For me the difference has been that write-ups now happen in the meeting rather than in a backlog, call prep takes a couple of minutes instead of half an hour of scrolling through Slack and Salesforce, and nothing falls through the cracks between calls. The compounding effect is the real gain: every note I file makes the next prep, the next follow-up, and the next customer email better, because the corpus is the context.

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

### Before you start

Natoma/Nova is a prerequisite. It provides the read-only Google Calendar, Salesforce, Zoom and Slack MCP servers that `note-start`, `note-prep` and `note-salesforce-check` use. Get that connected first, otherwise those skills fall back to blank notes.

### Install

In CoCo Desktop, open **Agent Settings > Plugins**, click **Add a plugin**, then **Add from plugins catalog**. Search for `coco-notes` and install it. It lands in `~/.snowflake/cortex/plugins/coco-notes/`.

If you want to confirm you have the right listing first, this is it:

```
snow://skill_catalog/USER$JKINLEY.SKILL_SHARING.COCO_NOTES/
```

That unversioned form identifies the listing, but do not paste it into the **Import link** field: Desktop requires a version-pinned URI there and rejects one without it. Pin the version you want instead:

```
snow://skill_catalog/USER$JKINLEY.SKILL_SHARING.COCO_NOTES/versions/version$3/
```

Searching by name avoids the question entirely, which is why it is the route above. Either way, install is a copy rather than a live link, so to move to a later version afterwards use the **Sync** button (↻) on the plugin's detail page, or `cortex plugin update`.

### First-time setup

1. Create or open the folder you want to use for your notes.
2. Run `/coco-notes:note-setup`. It will:
   - Scaffold the repo (`COCO.md`, `_templates/`, `_internal/`, `_inbox/`, `.gitignore`).
   - Build your profile. The quickest route by far is to save your LinkedIn profile as a PDF (**More > Save to PDF**) and drop it in the folder first; otherwise it asks a few questions.
   - Build your writing-style guide from a short interview, and, if you provide samples (a blog post, an email), from your actual voice.
3. That's it. Take your first note with `/coco-notes:note-start`.

### Your first note

Run `/coco-notes:note-start`. It will offer to pull the meeting from your calendar. Capture as you go, rough and fragmented is fine, that is the point. When the call ends, say "process it": it cleans the note up in your voice, files it under the customer, extracts follow-ups, and walks the Salesforce use-case flow.

Get it into git straight away, and **make the repo private**. Your notes will contain customer detail that has no business being public.

```
gh repo create <your-notes-repo> --private --source=. --remote=origin
git add -A && git commit -m "First note"
git push -u origin main
```

`note-setup` writes a `.gitignore` for you, but check it before your first push.

### Day to day

- **Start a note:** `/coco-notes:note-start`, pick a meeting from your calendar, capture live, then say "process it".
- **Import a Zoom call:** `/coco-notes:note-import-zoom`.
- **Prep for a call:** `/coco-notes:note-prep <customer>`.
- **Find something:** `/coco-notes:note-ask "what did we agree with <customer> about X?"`.
- **See what's open:** `/coco-notes:note-follow-ups`.

### Make it yours

coco-notes is what I use, shaped around my accounts, my workflow and my voice, so you will find opinions in it that are mine rather than universal. Treat it as a starting point, not a finished product. Change the templates, rewrite the skills, add your own, throw away what you do not use.

The part worth real effort is the profile and the style guide, because that is what makes the output authentic. Rush it and you get competent generic prose you will end up rewriting, which defeats the purpose. Give it real samples of your writing and correct it when it gets your voice wrong. You want it to sound like you, not like me.

### Updating

When a new version is published, the plugin manager shows a pending upgrade. Click refresh in **Agent Settings > Plugins**. Your notes repo is untouched by plugin updates.

### Salesforce and calendar

`note-start`, `note-prep`, and `note-salesforce-check` use read-only Google Calendar and Salesforce MCP servers when available. If a server is not connected, the skills degrade gracefully (for example, `note-start` creates a blank note instead of prompting about the calendar). The Salesforce integration never writes. It drafts a comment for you to paste in.

### Feedback

Join **#coco-notes-feedback** for questions, and to compare notes with other people using it. I am particularly interested in what you change, especially if you build skills the rest of us should have.

## For maintainers

The canonical source of the skills lives in this repo under `skills/`.

Nothing lands on `main` directly. Every change goes on a branch and through a pull request, including mine. Review is the point: a skill is a prompt that runs against other people's notes repos, so a careless edit is not a local mistake, it ships to everyone on the next publish.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a PR. It covers the process, how a skill is put together, the naming and authoring standards, the rules for SQL in skills, and the checklist a contribution is reviewed against.

Once changes are merged to `main`, a release is a deliberate act: bump `version` in `.cortex-plugin/plugin.json` on `main`, tag that commit, then publish to the account catalog with the `share-skill-and-plugin` flow. Only a republish with a higher version surfaces an update to installed users. Publish from `main` only, never from a branch, so that what is in the catalog always matches what is in the repo. Contributors do not bump the version; see [CONTRIBUTING.md](CONTRIBUTING.md).

### Layout
```
coco-notes-plugin/
  .cortex-plugin/plugin.json     Manifest: name, description (carries the prerequisites), version, hooks
  skills/                        The 10 skills (canonical source)
  hooks/userpromptsubmit.sh      Install-completeness check + per-session rule injection
  assets/scaffold/               What note-setup writes into a new notes repo
    COCO.md
    _templates/{meeting-note,interview-note}.md
    _internal/{user-profile,writing-style}.md   Generic placeholders
    .gitignore
  SETUP.md                       Post-install runbook; CoCo surfaces this after a catalog install
  README.md
  CONTRIBUTING.md                Contribution process and skill-authoring standards
```

### Conventions
- Skill frontmatter supports `name` and `description` only. Tool restrictions apply to agents, not skills.
- Reference bundled assets from a skill with `${CORTEX_PLUGIN_ROOT}/assets/...`. Never a bare relative path, and never `${CLAUDE_PLUGIN_ROOT}`.
- Skills reference notes-repo-relative paths (`_templates/`, `_internal/`, `<letter>/`); they work because they run against the user's scaffolded repo, so no per-user path edits are needed. A skill that depends on those paths must stop and point at `note-setup` when they are absent, rather than carrying on in a generic voice.
- The plugin ships one `UserPromptSubmit` hook, declared inline in the manifest. It stays silent outside a notes repo, prompts once for setup if the marker is missing, and otherwise supplies the user's writing style and profile in full on the first prompt of a session, then a short reminder on later prompts. `UserPromptSubmit` rather than `SessionStart` because `SessionStart` hooks run but their `additionalContext` is discarded; see the publishing constraints in [CONTRIBUTING.md](CONTRIBUTING.md).

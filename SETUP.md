# Setup

You have installed coco-notes. One step remains, and until you do it the `note-*` skills will stop and tell you so rather than draft in a generic voice.

## 1. Run setup

Open or create the folder you want to use for your notes, then run:

```
/coco-notes:note-setup
```

It scaffolds the repo, builds a profile of you, and interviews you briefly to build a writing-style guide. Two minutes, once, and it is what makes the output sound like you rather than like a language model. If you have your LinkedIn profile saved as a PDF (**More > Save to PDF**), drop it in the folder first and setup will read it instead of asking you questions.

Setup writes a marker at `_internal/.coco-notes-setup` when it finishes. That is how the plugin knows not to nag you again.

## 2. Check the plugin is live

Open a new session with your notes folder as the working directory. The plugin supplies your writing style and profile on your first prompt, so ask the agent:

> What do you know about how I write?

If it can answer, the hook is firing and the install is live. If it cannot, see Troubleshooting below.

Outside a notes folder the hook stays deliberately silent, so run this check from inside the repo you set up.

## Upgrading from an earlier version

Nothing to do. If you already have a notes repo, it keeps working and your writing style is picked up as before.

The detail, in case you are curious: this version introduces a `_internal/.coco-notes-setup` marker so the plugin can tell a set-up repo from a half-finished one. Repos created before the marker existed obviously do not have it, so the plugin also accepts a personalised `_internal/writing-style.md` as proof that setup ran. Your repo is recognised either way, and the marker appears on its own the next time you re-run `/coco-notes:note-setup`.

Existing decks are unaffected. The `slides-*` skills now ship two files under slightly different names, but that only changes what a new deck is built from, not decks you have already built.

## Prerequisites

None of these are enforced at install time. Everything here is optional in the sense that the plugin installs and runs without it; the affected skill degrades rather than crashes.

### The `note-*` family

Needs nothing beyond setup to take, file, and search notes. Three skills reach outside for convenience, and all three fall back to asking you:

| Skill | Wants | Without it |
| --- | --- | --- |
| `note-start` | Google Calendar MCP | You describe the meeting instead of picking it from a list |
| `note-import-zoom` | Zoom MCP | Cannot pull a transcript, so nothing to import |
| `note-start`, `note-salesforce-check` | Salesforce MCP (read-only) | The use-case flow is skipped |

At Snowflake these come from Natoma/Nova. Connect that first and all three are covered at once.

### The `slides-*` family

Heavier, and only needed if you build decks:

| Skill | Needs |
| --- | --- |
| `slides-narrate` | An ElevenLabs API key, plus `ffmpeg` or macOS `afinfo` for clip timing |
| `slides-deploy` | Docker, and an authenticated `snow` CLI with rights to create a service or app |

`slides-build` needs nothing. You can build a deck and skip narration and hosting entirely.

## Troubleshooting

**The `note-*` skills say the repo is not set up, but it is.** They look for `_internal/writing-style.md` relative to the working directory. Check you are in the folder you ran setup in.

**Nothing is injected on your first prompt.** The hook runs in a non-interactive shell that reads only `~/.zshenv`, not `.zshrc` or `.zprofile`. It is written in plain `sh` and resolves its tools by absolute path specifically to avoid this, so a PATH problem is unlikely, but if you have overridden `sh`, `sed`, `awk` or `tr` in an unusual way that is the first place to look. The failure is silent by design, so absence of context is the only symptom.

**Setup ran but the marker is missing.** Re-run `/coco-notes:note-setup`. It is safe to run repeatedly; it will ask before overwriting anything.

**A skill references a file it cannot find.** Bundled files are referenced through `${CORTEX_PLUGIN_ROOT}`. If that variable is not resolving, the plugin has not registered properly. Remove and reinstall it from the catalog.

## Your data

Your notes, profile, and writing style live in your own repo and never leave your machine and your Snowflake account. Nothing is sent back to the plugin or its author.

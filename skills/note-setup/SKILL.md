---
name: note-setup
description: "One-time onboarding for a new coco-notes repo: scaffold the folder structure, bootstrap the user's profile (ideally from their LinkedIn PDF), and build a personal writing-style guide from a short interview and optional writing samples. Use when: setting up coco-notes for the first time, onboarding, initialising a notes repo, creating my profile or writing style. Triggers: note setup, set up coco-notes, onboard, initialise notes, bootstrap profile, create my profile, create writing style, first time setup."
---

# Note Setup

Onboard a new user into a coco-notes repository. Run this once, in the folder the user wants to use for their notes (ideally empty or new). It does three things in order: scaffold the repo, bootstrap the profile, and build the writing-style guide. At the end the user has a working notes repo that every other `coco-notes` skill runs against.

The scaffold sources live in this plugin's `assets/scaffold/`. Reference them with `${CLAUDE_PLUGIN_ROOT}/assets/scaffold/` when reading or copying.

## Part A — Scaffold the repo

1. **Confirm the location.** Check the current working directory. If it already contains a `COCO.md`, the repo is likely set up already: tell the user and ask whether to continue (re-run profile/style) or stop. If the folder has unrelated files, confirm this is the intended notes folder before writing anything.
2. **Create the structure**, copying from `${CLAUDE_PLUGIN_ROOT}/assets/scaffold/`:
   - `COCO.md` — the project instructions.
   - `_templates/meeting-note.md` and `_templates/interview-note.md`.
   - `_internal/user-profile.md` and `_internal/writing-style.md` — the generic placeholders (Parts B and C replace these with personalised versions).
   - `.gitignore`.
   - `_inbox/` — create the empty inbox (add a `.gitkeep` if the platform needs it to track an empty dir).
3. **Offer git.** Ask whether to `git init` the folder now. If yes, initialise and make no commit yet (the user commits when ready). Do not create a remote.
4. Tell the user the repo is scaffolded, then move to Part B.

## Part B — Bootstrap the profile

The profile (`_internal/user-profile.md`) is read at the start of every session so the assistant tailors output to who the user is. Build it from the best source available.

1. **Recommend the LinkedIn route first.** Say:
   > "The quickest way to build your profile is from your LinkedIn PDF. Open your LinkedIn profile, click **More**, choose **Save to PDF**, and drop the file into this folder (or share it with me here). I will read it and draft your profile. Prefer not to? I can ask you a few questions instead."
2. **If a PDF (or CV/resume) is provided**, read it and draft `_internal/user-profile.md` covering: current role and focus, background and years of experience, notable career history, technical or domain expertise, and working style. Write it in clear prose, first person is fine. Keep it factual to the source; do not invent detail.
3. **If no document is provided**, ask a short set of questions and draft from the answers:
   - Current role and team
   - Main focus areas / what you spend your time on
   - Domains or industries you work in
   - Seniority and years of experience
   - Anything about how you like to work that the assistant should know
4. **Confirm.** Show the drafted profile and let the user correct it before saving. Save to `_internal/user-profile.md`, replacing the placeholder.

## Part C — Build the writing-style guide

The style guide (`_internal/writing-style.md`) governs the voice of everything the assistant drafts. Build it from a short interview, then refine from samples if the user has any.

1. **Run the questionnaire** (question tool). Ask:
   - **English variant:** British, American, or other (name it).
   - **Tone:** formal, friendly-professional, or casual.
   - **Format bias:** prose-first, or comfortable with bullet lists.
   - **Email opener/closer:** e.g. "Hi [name]," and "Regards, [name]" — capture their actual sign-off.
   - **Pet-hates to ban:** offer common ones to toggle (LLM tells like "leverage"/"delve"/"it's worth noting", em dashes, arrows, emojis, exclamation marks) and let them add their own.
2. **Offer sample analysis.** Say:
   > "If you paste or point me to a couple of samples of your writing — a blog post, an email, a Slack message — I will analyse them to capture your actual voice. Otherwise I will build the guide from your answers."
   - **If samples are provided**, read them and infer: typical sentence length and rhythm, paragraph length, hedging habits, punctuation tendencies, vocabulary and recurring phrases, and how tone shifts by channel. Fold these observations into the guide.
   - **If no samples**, build from the questionnaire alone and note at the top that the guide can be sharpened later by re-running with samples.
3. **Synthesise `_internal/writing-style.md`** in this structure (mirror the sections so downstream skills find what they expect): Core voice; Sentence and paragraph structure; Technical depth and plain language; Directness and hedging; Format preferences; Channel-specific guidance (notes, Slack, email, documents); Openers and closers; Things to avoid; English conventions; Tone calibration by audience.
4. **Confirm and save**, replacing the placeholder.

## Finish

Summarise what was created and point the user to the next step:
- "Your coco-notes repo is ready. Start a note any time with `/coco-notes:note-start` — it will offer to pull a meeting from your calendar. Ask across your notes with `/coco-notes:note-ask`, prep for a call with `/coco-notes:note-prep`, and roll up open actions with `/coco-notes:note-follow-ups`."
- Mention they can re-run `/coco-notes:note-setup` any time to refresh their profile or writing style.
- Remind them `_internal/` and their notes are theirs; nothing here is shared back to the plugin.

## Notes

- This skill writes into the user's own repo, never into the plugin. Treat `${CLAUDE_PLUGIN_ROOT}/assets/scaffold/` as read-only source.
- Never fabricate profile detail. If the source is thin, keep the profile short and say so.
- The generic placeholders are a safe fallback: if the user skips Parts B and C, the repo still works with neutral defaults.

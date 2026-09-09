# Coco-Notes — Project Instructions

A note-taking system for tracking customer meetings, technical discussions, action items, and internal activities (interviews, team planning, slides) across your engagements.

The skills that drive this workflow (`note-start`, `note-prep`, and the rest) are provided by the **coco-notes plugin** you installed, not by this repo. This file tells those skills how your notes are organised.

## Directory Structure

```
_inbox/              Drop zone for quick captures and live notes
_internal/           Non-customer assets
  user-profile.md    Your background, role, and working style                    [pinned]
  writing-style.md   The voice and style guide all generated text follows        [pinned]
  people/
    interviews/
      YYYY/
        MM/          Interview notes — one file per candidate                    [pinned]
    1-1s/
      <person-slug>/
        YYYY-MM-DD-topic.md            One-to-one notes, one folder per person
  reporting/
    qbr/
      FYxxQx/                          One folder per cycle, self-contained
        index.html                     The deck
        assets/                        Deck images
        notes/                         Prep notes and supporting data
  slides/
    <deck-name>/     Standalone internal decks and presentation assets
  artefacts/
    <tool>/<name>/   Reusable technical assets (flow definitions, configs, code)
  brand/             Local cache of brand assets — untracked
  reference/         Third-party papers and PDFs — untracked
_templates/          Standard note formats (meeting-note, interview-note)
<letter>/            Alphabetical customer folders
  <customer>/
    profile.md                         Customer profile (contacts, team, initiatives, use case comments)
    YYYY/
      MM/
        YYYY-MM-DD-topic-slug.md       Individual meeting notes
        YYYY-MM-DD-workshop-slug/      Workshop assets (self-contained)
```

Paths marked `[pinned]` are hard-coded by the coco-notes plugin's skills. Moving them breaks the skills, so leave them where they are.

Each folder under `_internal/` has a README explaining what belongs in it. Delete any you do not need — `reporting/` and `1-1s/` are the usual candidates.

### Where a deck lives

Three homes, and the deck's owner decides which:

- **Customer deck** — with the customer, at `<letter>/<customer>/YYYY/MM/YYYY-MM-DD-workshop-slug/`. Self-contained, so it stays intelligible next to the meeting note that explains it.
- **Reporting deck** — with its cycle, at `_internal/reporting/qbr/FYxxQx/`. The cycle owns the deck, its prep notes and its data together.
- **Anything else** — `_internal/slides/<deck-name>/`. Standalone internal decks with no customer and no cycle.

Every deck is self-contained: asset paths are relative to the deck folder, because a deck may be copied elsewhere or containerised and deployed on its own. Never reference an asset across folders.

---

## Session Start — Always Read First

At the start of every session in this project, read these two files before doing anything else:

1. `_internal/user-profile.md` — your background, role, technical expertise, and working style. The authoritative reference for who you are. Use it to tailor all output, and to fill the account-team entry when creating a new customer profile.
2. `_internal/writing-style.md` — the full writing-style guide. All content must conform to it.

This applies regardless of whether the session is a customer note, an internal document, a code task, or a quick question.

Run the `note-setup` skill once if these files are still the generic placeholders — it builds a personalised profile and writing-style guide.

---

## Voice & Style

All text generated, reformatted, or drafted in this project follows the writing-style guide at `_internal/writing-style.md`. That guide is the single source of truth for voice, tone, spelling conventions, formatting preferences, and the words and patterns to avoid. Do not restate or second-guess those rules here; read the guide and apply it.

---

## Session Behaviour

### When working in a customer folder
1. Read `profile.md` first to understand who the customer is, who's on the account team, and what's active.
2. When creating a new note, use the template from `_templates/meeting-note.md`.
3. Name new notes as `YYYY-MM-DD-topic-slug.md` and save to `YYYY/MM/` within the customer folder.

### When working in `_internal/people/interviews/`
1. When creating a new interview note, use the template from `_templates/interview-note.md`.
2. Name new notes as `YYYY-MM-DD-candidate-name.md` and save to `YYYY/MM/` within `_internal/people/interviews/`.

### When working in `_internal/people/1-1s/`
1. One folder per person, named `<person-slug>` (lowercase, hyphenated).
2. Name notes as `YYYY-MM-DD-topic.md` inside that person's folder. No year/month nesting — a one-to-one series reads better as a flat chronological list per person.

### When working in `_internal/reporting/`
1. A reporting cycle owns everything about it: the deck, its prep notes, its supporting data.
2. QBRs live at `_internal/reporting/qbr/FYxxQx/`, with the deck as `index.html`, images in `assets/`, and prep notes in `notes/`.
3. Start a new folder for each cycle rather than editing the last one. Previous cycles are the record of what was said.

### Workshop prep and assets
When building workshop prep or assets, create a dated folder at `<letter>/<customer>/YYYY/MM/YYYY-MM-DD-workshop-slug/`. Keep all assets self-contained inside it. The companion meeting note (`YYYY-MM-DD-workshop-slug.md`) sits alongside the folder at the same level.

### When in `_inbox/` or the project root
- Quick captures go in `_inbox/` with a date prefix.
- Quick captures don't need to follow the full template — just get the content down.

## Capturing Meetings

A meeting becomes a filed note one of three ways. All three converge on the same filing and Salesforce use-case flow.

- **Live capture** — run `/coco-notes:note-start`. If the Google Calendar MCP is available it offers to list today's, tomorrow's, or this week's meetings; pick one and the note is pre-filled from the invite, or choose a blank note. Type directly in the editor during the call, then tell CoCo to process it.
- **Pasted transcript or raw notes** — paste the text and ask CoCo to file it.
- **Zoom recording** — run `/coco-notes:note-import-zoom` to pull a finished Zoom transcript and file it.

### Filing (all capture routes)
1. Extract customer, date, attendees, topic, tags.
2. Reformat to the standard template, applying the writing-style guide (clean shorthand into clear prose; preserve detail).
3. File to `<letter>/<customer-slug>/YYYY/MM/YYYY-MM-DD-topic-slug.md`, or `_inbox/` if the customer is unclear.
4. Run the Salesforce use-case flow.
5. Commit if the repo is under git.

## Note Templates

- **Customer meetings** — `_templates/meeting-note.md`: YAML frontmatter (customer, date, topic, tags); heading `# YYYY-MM-DD | Customer — Topic`; attendees line; `## Notes`, `## Follow-up`.
- **Interviews** — `_templates/interview-note.md`: frontmatter (candidate, date, role, interviewers, stage); `## Role Summary`, `## Candidate Summary`, `## Interview Themes & Questions`, `## Notes`, `## Recommendation`, `## Follow-up`.

## Customer Profile Format

Each customer folder has a `profile.md`. Keep it current — it is the fast-read source of truth for the account. Structure:

```markdown
# Customer Name

## Contacts
- Name (role, email)

## Account Team
- Name (Role)

## Current Initiatives
- Active workstream 1

## Salesforce Use Case Comments

### UC-XXXXXX — Use Case Name
[Salesforce](https://snowforce.lightning.force.com/lightning/r/Use_Case__c/<id>/view)

MM/DD - Short shorthand entry. Current status, blockers, next steps.
```

Rules: max 4 entries per use case (drop the oldest when exceeding); do not draft an entry unless UC number, name, and Salesforce link are all confirmed; each use case gets its own `### UC-XXXXXX — Name` subsection.

## Salesforce Use Case Flow

After a customer note is filed, always run this flow. The Salesforce MCP is read-only, so CoCo fetches and drafts, but you paste the final comment into Salesforce by hand. The step-by-step lives in the `note-start` skill; in brief: offer to pull in-pursuit use cases (`Use_Case__c` where `Stage__c NOT IN ('0 - Not In Pursuit','8 - Use Case Lost')`), multi-select which apply, capture them in the note and `profile.md`, draft a concise exec-summary comment for the use case's Specialist Comments field, and open the record so you can paste it in.

## Skills (provided by the coco-notes plugin)

- **note-start** — start a live meeting or interview note (calendar pre-fill), and process/file it (includes the Salesforce use-case flow).
- **note-prep** — pre-call briefing for a customer.
- **note-import-zoom** — turn a finished Zoom transcript into a filed note.
- **note-follow-ups** — roll up open action items across all customer notes.
- **note-ask** — natural-language Q&A across the whole notes corpus.
- **note-salesforce-check** — flag use cases out of sync between Salesforce and profiles.
- **note-setup** — one-time onboarding (scaffold this repo, build your profile and writing-style guide).
- **slides-build / slides-narrate / slides-deploy** — build, narrate, and host cinematic HTML decks.

## Brand and Large Files

Before generating any branded visual asset (slides, decks, one-pagers), check your organisation's brand guidelines. For Snowflake, that is **https://www.snowflake.com/brand-guidelines/**. Do not improvise logo files, colour codes, or typography from memory.

If a brand asset is missing locally, download it into `_internal/brand/`, then copy it into the deck's own `assets/`. That folder is a download cache, not somewhere decks point at, and its contents are deliberately untracked. Do not commit brand assets.

Before staging any binary file over 1 MB, ask whether it should be tracked in git or left on local disk only. State the file size in the question. Never assume tracking.

The test is whether the file can be reproduced. Brand assets and third-party PDFs are re-downloadable, so they stay out of git. Generated artwork and approved audio usually cannot be regenerated identically, so they are worth tracking despite their size — losing them means losing them.

## Git Workflow

- If you keep this repo under git, commit messages follow: `notes: <description>` (or `interview: <candidate> - <role>` for interviews).
- Commit and push after each note is processed, not batched.

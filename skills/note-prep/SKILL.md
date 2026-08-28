---
name: note-prep
description: "Build a pre-call briefing for a customer from the notes folder: recent meetings, open follow-ups, active initiatives, and in-pursuit Salesforce use cases, pulled into a single pre-read. Use when: preparing for a customer call, getting up to speed before a meeting, pre-read, briefing. Triggers: prep, prep for, brief me on, pre-read, get me ready for, what's the latest on, catch me up on."
---

# Prep

Produce a concise pre-call briefing for a customer so the note-taker walks into the meeting up to speed. Read-only: this skill gathers and summarises, it does not change any notes.

Before starting, read `_internal/user-profile.md` and `_internal/writing-style.md` so the briefing is pitched at the right level and in the right voice. If `_internal/writing-style.md` is not there, you are not in a coco-notes repo, or setup has not run. Stop, say so, and tell the user to run `/coco-notes:note-setup` or change to their notes folder. Do not fall back to a generic voice.

## Steps

1. **Resolve the customer.** Take the customer from the request. Map to the folder `<first-letter>/<customer-slug>/`. If the slug is ambiguous, list the close matches and let the user pick.
2. **Read the profile.** Read `<customer>/profile.md` for contacts, account team, current initiatives, and the `## Salesforce Use Case Comments` history.
3. **Gather recent notes.** List the most recent notes under `<customer>/YYYY/MM/` (newest first) and read the latest few (default 3, more if the user asks). Note the date, topic, and key outcomes of each.
4. **Collect open follow-ups.** Scan the recent notes for unticked action items (`- [ ]`) and gather them with their owner and source note.
5. **Pull in-pursuit use cases (optional).** If Salesforce is available and the user wants it, resolve the account and fetch active use cases (see the `note-start` skill for the exact SOQL: `Use_Case__c` where `Stage__c NOT IN ('0 - Not In Pursuit','8 - Use Case Lost')`). Report UC number, name, and stage.

## Output

A short briefing, in the writing-style voice, with these parts:

- **Who** — key contacts and the account team, one line.
- **What's active** — current initiatives from the profile, trimmed to what matters for this call.
- **Recent history** — the last few meetings as dated one-liners (date, topic, outcome).
- **Open follow-ups** — unticked items with owners, so nothing is dropped.
- **In-pursuit use cases** — UC number, name, stage (if pulled).
- **Suggested focus** — two or three things worth raising or closing on this call, inferred from the above.

Keep it tight: a pre-read, not a report. Prose and short lists, no filler.

---
name: note-import-zoom
description: "Turn a finished Zoom meeting into a filed customer note: find the meeting, pull its transcript, then reuse the note-start filing and Salesforce use-case flow. Use when: importing a Zoom call, filing a recorded meeting, turning a Zoom transcript into a note. Triggers: import zoom, zoom transcript, file my zoom call, import the recording, get the transcript from zoom."
---

# Import Zoom

Take a recorded Zoom meeting and file it as a customer note, without manual copy-paste of the transcript.

Before starting, read `_internal/user-profile.md` and `_internal/writing-style.md`. If `_internal/writing-style.md` is not there, you are not in a coco-notes repo, or setup has not run. Stop, say so, and tell the user to run `/coco-notes:note-setup` or change to their notes folder. Do not fall back to a generic voice.

## Steps

1. **Find the meeting.** From the request (topic, customer, or date), search recent Zoom meetings and recordings. If several match, show the candidates (topic, date, duration) and let the user pick. Default to the most recent if the request clearly points to one.
2. **Pull the transcript.** Retrieve the meeting's transcript asset (VTT/text). If the transcript is not yet ready, tell the user and stop, since a recording without a transcript can't be filed cleanly. If only an audio/video recording exists, say so and offer to proceed once the transcript is available.
3. **Extract the essentials.** From the transcript and meeting metadata, pull: customer name, date (the meeting date, not today), attendees, topic, and action items. Infer the customer from external attendee domains, ignoring internal ones.
4. **Hand off to the standard filing flow.** From here, follow the `note-start` **Post-Call Processing** steps exactly:
   - Reformat into the meeting-note template, applying the writing-style guide. Clean the transcript into readable prose grouped by topic; preserve detail, do not over-summarise. A raw transcript is verbose, so structure it, but keep the substance.
   - File to `<letter>/<customer-slug>/YYYY/MM/YYYY-MM-DD-topic-slug.md` using the meeting date.
   - Run the Salesforce use-case flow (steps 9-16 of `note-start`): offer to pull in-pursuit use cases, multi-select, capture in note and profile, draft the exec-summary comment, open the record to paste.
   - Commit and push with `notes: <customer> - <topic slug>`.

## Notes

- Use the meeting's own date for the filename and frontmatter, not the date of import.
- Do not store the raw transcript verbatim in the repo; file the cleaned note. If the user wants the raw transcript kept, drop it in `_inbox/` and tell them.
- This skill only reads from Zoom. It never deletes or modifies anything in Zoom.

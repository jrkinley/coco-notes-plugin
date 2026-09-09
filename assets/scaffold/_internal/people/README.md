# People

Notes about people rather than about customers or projects.

- `interviews/YYYY/MM/YYYY-MM-DD-<candidate-slug>.md` — hiring interviews, one file per candidate,
  filed by calendar year and month. Created with `_templates/interview-note.md`.
- `1-1s/<person-slug>/YYYY-MM-DD-topic.md` — one-to-ones, one folder per person, notes flat inside it.

One-to-ones are flat per person on purpose. A series with the same person reads better as a single
chronological list than split across year and month folders. Interviews are the opposite: you rarely
reread one, but you often want to know who was seen in a given month.

Delete `1-1s/` if you do not run one-to-ones.

> `interviews/` is a path the coco-notes plugin hard-codes. Renaming or moving it will break the
> `note-start` interview flow.

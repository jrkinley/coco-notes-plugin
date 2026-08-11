---
name: note-ask
description: "Answer a natural-language question across the whole notes corpus, citing the notes the answer came from. Use when: asking what was said about a topic, who owns something, when a decision was made, searching across customers, recalling a detail from past meetings. Triggers: ask notes, search my notes, what did we say about, when did we, who at, find the note where, across all customers, what do we know about."
---

# Ask Notes

Answer a question by searching and reading across the notes corpus, then synthesising a grounded answer with citations. Read-only.

Before answering, read `_internal/writing-style.md` for voice.

## Steps

1. **Turn the question into search terms.** Pull the key entities (customer, person, product, project) and likely phrasings. Include synonyms and Snowflake product names where relevant (e.g. Openflow, Snowpipe Streaming, Iceberg, Cortex).
2. **Search broadly, then narrow.** Grep across `<letter>/**/*.md`, `_internal/**/*.md`, and `_inbox/`. Start with the strongest term, widen if thin. If the question names a customer, search that folder first, then the corpus for cross-references.
3. **Read the hits that matter.** Open the most relevant notes and profiles. Prefer the profile for "current state" questions and dated notes for "what happened / when" questions.
4. **Synthesise.** Answer the actual question directly, in the writing-style voice. Distinguish what the notes state from what you're inferring. If the notes conflict or a detail is stale, say so and give the dates.
5. **Cite.** Reference the notes the answer draws on as `file_path` with the note date and topic, so the user can jump to the source. Cite the specific note, not just the customer folder.

## Rules

- Ground every claim in a note. If the corpus doesn't cover it, say so plainly rather than guessing — do not fill gaps from general knowledge or memory.
- Quote sparingly and only when the exact wording matters; otherwise summarise.
- This skill never edits notes. It reads and answers.

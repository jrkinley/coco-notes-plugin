---
name: note-follow-ups
description: "Roll up open action items across all customer notes into one list, grouped by customer, so nothing is dropped. Use when: reviewing outstanding actions, what do I owe, open follow-ups, my action items, what's outstanding. Triggers: follow-ups, follow ups, open actions, action items, what do I owe, outstanding items, my todos across customers, what's still open."
---

# Follow-ups

Scan the whole notes corpus for open action items and present them as one organised list. Read-only: this skill reports, it does not tick items off or edit notes.

Before starting, read `_internal/writing-style.md` for voice.

## Steps

1. **Find open items.** Search all customer notes (`<letter>/<customer>/YYYY/MM/*.md`) and interview notes for unticked checkboxes: lines matching `- [ ]`. Ticked items (`- [x]`) are done — ignore them.
2. **Attach context to each item.** For every open item capture: the customer, the source note (date and topic), the item text, and any owner named in the line.
3. **Scope, if the user asked.** If the request names a customer, a timeframe, or "mine only", filter accordingly. "Mine" means items owned by the note-taker (from `_internal/user-profile.md`) or with no explicit owner. Default is everything still open.
4. **Order by relevance.** Group by customer. Within a customer, newest source note first. Optionally surface a short "oldest still open" callout at the top, since long-open items are the ones most likely to have slipped.

## Output

Grouped by customer:

```
### <Customer>
- [ ] <item text> — <owner> · <source note date, topic>
```

End with a one-line count (e.g. "17 open items across 6 customers"). If the user wants, offer to open a specific customer's note to action an item. Do not edit any note as part of this skill; changing an item's state happens in the note itself.

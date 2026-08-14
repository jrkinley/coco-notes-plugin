# gong-recordings

A Cortex Code skill that pulls your Gong-recorded calls from Snowhouse and surfaces AI-generated summaries, outcomes, next steps, and recording links — all from within the IDE.

## What it does

Invoke it by typing `/gong-recordings` or naturally asking things like:

- "pull my Gong calls from last week"
- "show my recorded meetings this month"
- "what calls did Sarah have last week?"
- "gong summary for August"

The skill looks up your calls in `GONG_SHARE.GONG_DATA_CLOUD` using your connected Snowflake user, then formats each call with:

- Title, date, time (PT), duration, internal/external scope
- AI-generated brief (Gong Spotlight)
- Outcome and next steps
- Direct link to the Zoom recording

It can also fetch full transcripts on request.

## Requirements

- **Snowflake account:** `SFCOGSOPS-SNOWHOUSE_AWS_US_WEST_2`
- **Access to:** `GONG_SHARE.GONG_DATA_CLOUD` (views: `CALLS`, `USERS`, `CONVERSATION_PARTICIPANTS`, `CALL_RECORDINGS`, `CALL_TRANSCRIPTS`)
- **Tool:** [Cortex Code Desktop](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code) connected to Snowhouse

Your Snowhouse username must match your Snowflake email (`JETHOMAS` → `jethomas@snowflake.com`). This is true for all standard Snowflake employee accounts.

## Installation

Copy the `gong-recordings/` folder into your Cortex Code skills directory:

**Global (available in all projects):**
```bash
cp -r gong-recordings ~/.snowflake/cortex/skills/
```

**Project-local (only in current repo):**
```bash
cp -r gong-recordings .cortex/skills/
```

The skill is available immediately on the next invocation — no restart or registration needed.

## File structure

```
gong-recordings/
├── SKILL.md    # Skill logic and SQL
└── README.md   # This file
```

## Notes

- Only meetings where the Gong bot was present appear in results. Calls recorded via Gong Dialer or imported telephony calls are also included if captured.
- Times are shown in PT. To change timezone, edit the `CONVERT_TIMEZONE` call in `SKILL.md`.
- The skill defaults to last calendar week. Any natural language date range works ("this month", "yesterday", "Q3").

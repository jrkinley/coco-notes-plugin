---
name: gong-recordings
description: "Pull Gong call recordings and AI summaries from Snowhouse for meetings the current user attended. Use when: user asks about their Gong calls, meeting summaries, recorded meetings, call recordings, what meetings they had, Gong activity. Triggers: gong, my calls, my meetings, recorded calls, call summary, meeting summary, gong recordings, what did I discuss, calls last week."
---

# Gong Recordings

Pull Gong-recorded calls from Snowhouse for the current user and present AI-generated summaries.

## Data Sources

All data lives in `GONG_SHARE.GONG_DATA_CLOUD` in Snowhouse (account: `SFCOGSOPS-SNOWHOUSE_AWS_US_WEST_2`):
- `USERS` — maps email → `USER_ID`
- `CONVERSATION_PARTICIPANTS` — links users to calls by `CONVERSATION_KEY`
- `CALLS` — call metadata + AI spotlight fields (brief, outcome, next steps, key points)
- `CALL_RECORDINGS` — duration in seconds

## Workflow

### Step 1: Resolve Date Range

If the user didn't specify a date range, default to **last calendar week** (Mon–Sun).

Compute from today's date (available in the environment):
- `start_date` = most recent Monday minus 7 days
- `end_date` = start_date + 7 days (exclusive)

If the user specifies a range (e.g. "last month", "this week", "August 4-10"), parse it into explicit dates.

### Step 2: Resolve User Email

Derive the user's email from the connected Snowflake session — usernames do NOT map predictably to emails (e.g. `JETHOMAS` → `jeff.thomas@snowflake.com`), so always look it up:

```sql
SELECT EMAIL
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE LOGIN_NAME = CURRENT_USER()
  AND DELETED_ON IS NULL
```

If the user explicitly asks about a colleague, search by name:
```sql
SELECT USER_ID, EMAIL_ADDRESS, FIRST_NAME, LAST_NAME, TITLE
FROM GONG_SHARE.GONG_DATA_CLOUD.USERS
WHERE EMAIL_ADDRESS ILIKE '%<name>%'
   OR FIRST_NAME ILIKE '%<name>%'
   OR LAST_NAME  ILIKE '%<name>%'
```

### Step 3: Query Calls

Run this query, substituting `<email>`, `<start_date>`, `<end_date>`:

```sql
SELECT
    c.TITLE,
    c.EFFECTIVE_START_DATETIME::DATE                                         AS call_date,
    TO_CHAR(CONVERT_TIMEZONE('America/Los_Angeles', c.EFFECTIVE_START_DATETIME), 'HH12:MI AM') AS start_time_pt,
    ROUND(cr.DURATION / 60.0)                                                AS duration_minutes,
    c.SCOPE,
    c.CALL_SPOTLIGHT_BRIEF                                                   AS brief,
    c.CALL_SPOTLIGHT_OUTCOME                                                 AS outcome,
    c.CALL_SPOTLIGHT_NEXT_STEPS                                              AS next_steps,
    c.CALL_SPOTLIGHT_KEY_POINTS                                              AS key_points,
    c.CALL_URL
FROM GONG_SHARE.GONG_DATA_CLOUD.CALLS c
JOIN GONG_SHARE.GONG_DATA_CLOUD.CONVERSATION_PARTICIPANTS p
    ON c.CONVERSATION_KEY = p.CONVERSATION_KEY
LEFT JOIN GONG_SHARE.GONG_DATA_CLOUD.CALL_RECORDINGS cr
    ON c.CONVERSATION_KEY = cr.CONVERSATION_KEY
WHERE p.EMAIL_ADDRESS = '<email>'
  AND c.EFFECTIVE_START_DATETIME >= '<start_date>'
  AND c.EFFECTIVE_START_DATETIME <  '<end_date>'
  AND c.IS_DELETED = FALSE
ORDER BY c.EFFECTIVE_START_DATETIME
```

### Step 4: Present Results

For each call, format as:

```
### <TITLE>
**Date:** <call_date> | **Time:** <start_time_pt> PT | **Duration:** ~<duration_minutes> min | **Type:** <SCOPE>
**Recording:** <CALL_URL>

**Summary:** <brief>

**Outcome:** <outcome>          ← omit if null/empty

**Next Steps:**
- <each item from next_steps JSON array>    ← omit if null/empty

**Key Points:**
- <each item from key_points JSON array>    ← omit if null/empty
```

`next_steps` and `key_points` are JSON arrays — render each element as a bullet. Skip the section entirely if null or empty.

If zero rows are returned: "No Gong-recorded calls found for `<email>` between `<start_date>` and `<end_date>`. Calls only appear here if the Gong bot was present in the meeting."

### Step 5: Optional Follow-Up

After presenting results, offer:
- "Want the full transcript for any of these calls?"
- "Want to see a different date range?"

To fetch a transcript, query `GONG_SHARE.GONG_DATA_CLOUD.CALL_TRANSCRIPTS` on `CONVERSATION_KEY` and parse the `TRANSCRIPT` VARIANT column.

## Stopping Points

Run end to end without pausing, except:
- User asks about a colleague → confirm their email before querying
- Date range is genuinely ambiguous → clarify before querying

## Output

Per-call summaries with date, time, duration, AI brief, outcome, next steps, key points, and a direct recording link.

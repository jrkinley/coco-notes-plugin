---
name: note-salesforce-check
description: "Flag use cases that are out of sync between Salesforce and the customer profiles: active in Salesforce but missing from a profile, or recorded in a profile but closed/lost in Salesforce. Use when: checking use case hygiene, reconciling Salesforce with notes, what use cases am I missing, are my profiles up to date. Triggers: salesforce check, uc check, reconcile salesforce, use case hygiene, out of sync use cases, stale use cases, missing use cases."
---

# Salesforce Check

Reconcile the customer profiles against Salesforce so the profiles stay honest. The Salesforce MCP is **read-only**: this skill reports drift and proposes profile edits, but never writes to Salesforce.

Before starting, read `_internal/writing-style.md` for voice. If that file is not there, you are not in a coco-notes repo, or setup has not run. Stop, say so, and tell the user to run `/coco-notes:note-setup` or change to their notes folder. Do not fall back to a generic voice.

## Scope

Run for one customer (if named) or across all customer folders. For each customer:

1. **Read the profile.** Collect the UC subsections under `## Salesforce Use Case Comments` — the UC numbers, names, and Salesforce links already recorded.
2. **Fetch Salesforce.** Resolve the account by name, then query its use cases and their stages:
   ```sql
   SELECT Id, Name, Name__c, Stage__c, Use_Case_Status__c
   FROM Use_Case__c
   WHERE Account__c = '<accountId>'
   ```
   `Name` is the UC number; `Name__c` the descriptive name. Treat `Stage__c NOT IN ('0 - Not In Pursuit','8 - Use Case Lost')` as in-pursuit; `8 - Use Case Lost` and the completed stages (`6`, `7`) as closed.

3. **Compare and flag:**
   - **Missing from profile** — in-pursuit in Salesforce but no subsection in the profile. Likely should be added.
   - **Stale in profile** — a UC in the profile that is now `8 - Use Case Lost` or deployed/complete in Salesforce. Likely should be archived or its status noted.
   - **Broken or mismatched link** — the profile's Salesforce link doesn't resolve to that UC's record, or the recorded name differs from `Name__c`.

## Output

Grouped by customer, only customers with drift:

```
### <Customer>
- MISSING: UC-XXXXXX <name> (Stage N) — in pursuit in SF, not in profile
- STALE:   UC-XXXXXX <name> — profile has it; SF stage is '8 - Use Case Lost'
- LINK:    UC-XXXXXX — profile link points to a different record
```

End with a one-line summary count. Then offer to apply the profile-side fixes (add missing subsections, note stale ones) on the user's approval — those edits go to `profile.md` only. Salesforce itself is never modified by this skill; any Salesforce change is for the user to make by hand.

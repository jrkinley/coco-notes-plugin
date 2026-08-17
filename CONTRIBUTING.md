# Contributing to coco-notes

New skills are welcome, and so are fixes to the ones that are here. This file is what a contribution is reviewed against, so read it before you open a pull request rather than after.

One thing to hold on to while you read the rest: a skill is a prompt that runs against other people's notes repos, on their Snowflake connection, in their voice. A careless edit is not a local mistake, it ships to everyone on the next publish. That is why review is strict and why the bar for "it works on my machine" is not the bar.

## Process

Nothing lands on `main` directly, including changes from the maintainer.

1. Fork the repo, or branch off `main` if you have write access: `git switch -c <short-description>`.
2. Make the change. Use a descriptive branch name and a descriptive PR title, one that tells a reviewer what changed and why.
3. Test the skill locally from your branch, against a real notes repo, before asking for review. Say in the PR description what you ran and what you saw.
4. Open a PR and get a review.

Do not touch `version` in `.cortex-plugin/plugin.json`. Versioning belongs to the release, not to the pull request, and the maintainer handles it (see Releasing). Say in your PR description whether you think the change is a patch, a minor, or breaking, and leave the number alone.

## Anatomy of a skill

One directory per skill under `skills/<name>/`, containing exactly one `SKILL.md`. Add an `assets/` subdirectory only if the skill ships files it needs at runtime, as the `slides-*` skills do.

Do not add a per-skill `README.md`. The skill body is the documentation, and the repo `README.md` is the index. A third copy drifts from the other two, and it will be the copy a reviewer misses.

Frontmatter supports `name` and `description` only. Tool restrictions apply to agents, not skills.

```yaml
---
name: note-example
description: "One sentence on what it does. Use when: the situations that should trigger it. Triggers: short comma-separated phrases a user might actually type."
---
```

The directory name, the frontmatter `name`, and the invocation name must be identical. Get this wrong and the skill will not load.

## Naming

Skills belong to a family and take its prefix. `note-*` for anything that works with the notes corpus, `slides-*` for the deck pipeline. If your skill fits neither, that is worth discussing in an issue before you write it, because it is usually a sign the skill belongs in your own plugin rather than this one.

Name for what the skill does to the corpus, not for the system it talks to. `note-import-zoom` imports a call and files a note; the fact that Zoom is the source is the suffix, not the subject.

## Authoring standards

Write for the model, not for a human reader. Numbered steps, explicit table and column names, exact output format, and the specific conditions under which it should stop and ask. Look at `note-ask` for the short read-only shape and `note-start` for a long one with branches.

State in the first two lines whether the skill is read-only. Every skill that reports rather than writes says so plainly, and users rely on that.

Read `_internal/writing-style.md` before drafting any prose the user will see. This is what stops the output sounding generic, and it is the whole point of the harness. A skill that presents text to the user and skips this step will be sent back.

Degrade gracefully. Every external dependency, an MCP server, a Snowflake connection, a share, a warehouse, may be missing. Say what the skill does in that case. Failing with a raw error is not an answer, and neither is pretending the dependency is guaranteed.

Declare every dependency in the skill body: accounts, databases, schemas, views, roles, privileges, and MCP servers. If the skill reads `SNOWFLAKE.ACCOUNT_USAGE`, that is a dependency, and plenty of field roles do not have it.

Do not hardcode anything local to you. Timezones, account names, warehouses, regions, and paths under your home directory all fail for the next person. `TIMESTAMP_TZ` columns already render in the session timezone, so converting to your own is a step backwards. Where a default is genuinely needed, make it overridable by asking, not by editing `SKILL.md`.

Be careful with customer content. Transcripts and call recordings are customer conversation records. If a skill can surface them, warn about volume, and never send them anywhere outside the user's own machine and Snowflake account.

## SQL in skills

Run every query against a real account and paste what came back into the PR. A query that compiles is not a query that is correct.

Confirm the columns exist and check their types before you write against them. `DESCRIBE VIEW` costs nothing. A `VARCHAR` holding JSON and a native `ARRAY` need different handling, and getting it wrong renders a raw blob to the user.

`CURRENT_USER()` returns the user's `NAME`, which is not the same as `LOGIN_NAME` for most users on most accounts. Any identity lookup should tolerate both, and should have an answer for the case where the result is empty or the email is NULL.

Check for join fanout. If a join can produce more than one row per entity, either prove it cannot in the data or guard it with `EXISTS` or `DISTINCT`. Filter `IS_DELETED` on every view that has it, not just the main one.

Describe what a query returns in terms of what it actually returns. If a column called `CALL_URL` holds meeting join links rather than recording links, the skill must not call it a recording link.

## When you add or rename a skill

Three lists have to stay in step, and the third is the one people forget:

- `README.md`, the skills table.
- `assets/scaffold/COCO.md`, the skills list. This file is copied into every user's notes repo, so a stale entry there is a stale entry in everyone's repo.
- `.cortex-plugin/plugin.json`, but only the `description`, and only if it no longer covers what the plugin does. Leave `version` alone.

## Checklist before you ask for review

- Descriptive branch and PR title, and a description that says what you tested.
- One `SKILL.md`, no per-skill `README.md`, directory name matches frontmatter `name`.
- Prefixed name in an existing family.
- Read-only stated if it is read-only, `_internal/writing-style.md` read if it drafts prose.
- Dependencies declared, missing-dependency behaviour defined, nothing local to you hardcoded.
- SQL run against a real account, with output pasted into the PR.
- `README.md` table and `COCO.md` list updated, `plugin.json` version untouched.

## Releasing

This section is for maintainers. Merging to `main` does not publish anything, so `main` can carry several merged changes before a release goes out.

A release is a deliberate act:

1. Decide the semver bump from everything merged since the last release, taking the largest impact in the batch.
2. Bump `version` in `.cortex-plugin/plugin.json` on `main`, in its own commit, with nothing else in it.
3. Tag that commit, `git tag -a v0.2.0 -m "..." && git push --tags`, so every catalogue version maps to an exact SHA.
4. Publish from that commit with the `share-skill-and-plugin` flow.

Publish from `main` only, never from a branch, so that what users install always matches what is in the repo. Only a republish with a higher version surfaces an update to installed users, which is why the bump and the publish belong in the same sitting.

## House style

Match the voice of the existing skills and the README. Prose first, bullet lists only for four or more genuinely parallel items, code blocks for anything that is code or a command. British English. No em dashes in prose; use commas, hyphens, or "to". Avoid the usual LLM tells, "leverage", "delve", "seamlessly", "it's worth noting". Skip the verbose intro and the trailing summary.

## Questions

Open an issue, or ask in **#coco-notes-feedback**. If you are planning something substantial, ask before you build it rather than after, so we can agree the shape while it is still cheap to change.

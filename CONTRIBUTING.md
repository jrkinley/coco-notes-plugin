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

## Publishing constraints

This plugin is published to the Cortex plugins catalog, and a catalog install is a copy of the plugin tree on someone else's machine, not a checkout of this repo. Several things that work fine here break there. The rules below exist because of how publishing works, not because of taste, so they are not negotiable in review.

**Reference bundled files through `${CORTEX_PLUGIN_ROOT}`.** Never a bare relative path, and never `${CLAUDE_PLUGIN_ROOT}`. A bare `assets/scaffold.html` resolves against the user's working directory, which is their notes repo, not the plugin. The `slides-*` skills are the trap here, because they use `assets/` for two different things: files the plugin ships, which take the prefix, and the deck being built, which stays bare. Say which you mean.

**Nothing in the tree may link to anything outside it.** Only the plugin tree is uploaded, so a skill pointing at `../docs` or at this file is a dead link for every installed user. `SETUP.md` in particular has to stand alone.

**Root-level hidden files are not uploaded.** Publish skips them, silently, and only `.cortex-plugin/` is carried. This is why hooks are declared inline in the manifest rather than in a root `.hooks.json`: the manifest always ships, a root dotfile does not. Put nothing load-bearing in one.

**Stage limits are 50 files, 2 MB per file, 10 MB total.** We are at 29 files and about 620 KB, so the realistic way to breach this is a skill shipping large binary assets. If yours needs more than a couple, raise it in an issue first.

**New prerequisites go in two places.** The manifest `description` and `SETUP.md`. The catalog does not enforce prerequisites and nothing checks them at install time, so an undocumented dependency is a consumer hitting an unexplained failure. Say what breaks without it and how the skill degrades.

**A skill that depends on the notes repo must fail loudly when it is absent.** Reading `_internal/writing-style.md` and carrying on when it is missing is worse than stopping, because the user gets generic prose that looks like it worked. Stop and point at `note-setup`.

**Verify a publish, do not assume it.** Flat verbatim upload is CLI-version-dependent. After publishing, `LIST` the committed `version$N`, not `live`, and check the file count and that your new files actually landed.

## When you add or rename a skill

Four lists have to stay in step, and the last two are the ones people forget:

- `README.md`, the skills table.
- `assets/scaffold/COCO.md`, the skills list. This file is copied into every user's notes repo, so a stale entry there is a stale entry in everyone's repo.
- `SETUP.md`, but only if the skill adds a prerequisite. This is what a new user reads after installing.
- `.cortex-plugin/plugin.json`, the `description`, and only if it no longer covers what the plugin does or is missing a new prerequisite. Leave `version` alone.

## Checklist before you ask for review

- Descriptive branch and PR title, and a description that says what you tested.
- One `SKILL.md`, no per-skill `README.md`, directory name matches frontmatter `name`.
- Prefixed name in an existing family.
- Read-only stated if it is read-only, `_internal/writing-style.md` read if it drafts prose, and the skill stops rather than guessing if it is missing.
- Bundled files referenced through `${CORTEX_PLUGIN_ROOT}`, nothing linking outside the plugin tree.
- Dependencies declared, missing-dependency behaviour defined, nothing local to you hardcoded.
- Any new prerequisite added to both the manifest `description` and `SETUP.md`.
- SQL run against a real account, with output pasted into the PR.
- `README.md` table, `COCO.md` list and `SETUP.md` updated, `plugin.json` version untouched.

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

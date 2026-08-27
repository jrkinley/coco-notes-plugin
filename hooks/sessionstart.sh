#!/bin/sh
# SessionStart hook for the coco-notes plugin.
#
# Two jobs, in order:
#   1. Install-completeness check. If the user is in a coco-notes repo but has
#      never run note-setup, say so. Without this an incomplete install looks
#      loaded but quietly drafts in a generic voice.
#   2. Rule injection. An installed plugin carries no persistent repo-style
#      rules, so the writing style and profile have to be re-supplied every
#      session or every skill falls back to a default voice.
#
# Written in POSIX sh and resolving its tools by absolute path on purpose. The
# host spawns hooks in a non-interactive shell that reads only ~/.zshenv, so
# anything relying on an interactive PATH fails silently.
#
# Output contract: stdout that is not valid JSON is injected verbatim as
# additionalContext, so this script prints plain text. Silence means no
# injection, which is the correct behaviour outside a notes repo.

set -u

CAT=/bin/cat
SED=/usr/bin/sed
HEAD=/usr/bin/head
WC=/usr/bin/wc

# Cap the injected payload. A long style guide should not dominate the session
# window, and a runaway file should not break session start at all.
MAX_BYTES=12000

# The host pipes event context as JSON on stdin, including cwd. Prefer that over
# PWD, but never depend on it: no jq here, and the field is not worth a hard
# dependency. Extract with sed, fall back to PWD.
STDIN_JSON=$("$CAT" 2>/dev/null || true)
REPO=$(printf '%s' "$STDIN_JSON" \
  | "$SED" -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | "$HEAD" -n 1)
if [ -z "${REPO:-}" ] || [ ! -d "$REPO" ]; then
  REPO=${PWD:-.}
fi

# Job 0: is this a coco-notes repo at all? If not, the user is working on
# something else entirely and must not be nagged. This is the common case.
if [ ! -f "$REPO/COCO.md" ] || [ ! -d "$REPO/_internal" ]; then
  exit 0
fi

MARKER="$REPO/_internal/.coco-notes-setup"
STYLE="$REPO/_internal/writing-style.md"
PROFILE="$REPO/_internal/user-profile.md"

# Job 1: setup has never completed. Point at the fix rather than half-working.
if [ ! -f "$MARKER" ]; then
  printf '%s\n' "coco-notes: this looks like a notes repo, but setup has not completed (no _internal/.coco-notes-setup marker). Tell the user their coco-notes install is incomplete and to run /coco-notes:note-setup in this folder to finish it. Until then, do not draft prose in a guessed voice: the writing-style guide may be a placeholder. The full runbook is in SETUP.md at the plugin root."
  exit 0
fi

# Job 2: inject the operating rules for this session.
printf '%s\n' "coco-notes: session context loaded from $REPO. The following is the user's own profile and writing-style guide. Apply the writing style to every piece of prose you draft for them, in this session and in any coco-notes skill you run."

emit_file() {
  _label=$1
  _path=$2
  [ -f "$_path" ] || return 0
  printf '\n--- %s (%s) ---\n' "$_label" "$_path"
  "$HEAD" -c "$MAX_BYTES" "$_path"
  _size=$("$WC" -c <"$_path" 2>/dev/null | "$SED" 's/[^0-9]//g')
  if [ -n "${_size:-}" ] && [ "$_size" -gt "$MAX_BYTES" ]; then
    printf '\n[truncated at %s bytes of %s. Read %s directly if you need the rest.]\n' \
      "$MAX_BYTES" "$_size" "$_path"
  fi
}

emit_file "Writing style" "$STYLE"
emit_file "User profile" "$PROFILE"

exit 0

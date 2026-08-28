#!/bin/sh
# UserPromptSubmit hook for the coco-notes plugin.
#
# Why this event and not SessionStart. An installed plugin carries no persistent
# repo-style rules, so the writing style has to be re-supplied by a hook. On
# CoCo Desktop and CLI 1.1.58, SessionStart hooks run but their additionalContext
# is discarded; UserPromptSubmit is injected. Verified with a probe plugin that
# registered four hooks emitting distinct canaries (SessionStart as top-level
# JSON, as nested hookSpecificOutput, and as bare text, plus UserPromptSubmit):
# all four ran, only the UserPromptSubmit canary reached the agent. The XO plugin
# reaches the same conclusion, injecting its primary discipline reminder on every
# UserPromptSubmit rather than relying on session start.
#
# Two jobs:
#   1. Install-completeness check. If the user is in a coco-notes repo but has
#      never run note-setup, say so once per session. Without this an incomplete
#      install looks loaded but quietly drafts in a generic voice.
#   2. Rule injection. The full writing style and profile go in on the first
#      prompt of a session; later prompts get a short reminder instead, because
#      the style guide runs to several thousand words and re-sending it every
#      turn would eat the context window for no gain.
#
# Written in POSIX sh and resolving its tools by absolute path on purpose. The
# host spawns hooks in a non-interactive shell that reads only ~/.zshenv, so
# anything relying on an interactive PATH fails silently. Invoked as
# `/bin/sh <script>` from the manifest, because the executable bit does not
# survive publish.
#
# Output contract: one JSON object on stdout. {"additionalContext":"..."} injects
# text; {"continue": true} is the no-op. Injected text is marked silent so the
# agent applies it without narrating it back at the user every turn.

set -u

# Byte-oriented, locale-independent text processing. Without this, BSD tr aborts
# with "Illegal byte sequence" the moment it meets input that is not valid UTF-8,
# and _internal/ is the user's own directory. In the C locale every tool here
# works on bytes, so multibyte characters pass through untouched and nothing can
# fail on encoding.
LC_ALL=C
export LC_ALL

CAT=/bin/cat
SED=/usr/bin/sed
HEAD=/usr/bin/head
WC=/usr/bin/wc
GREP=/usr/bin/grep
AWK=/usr/bin/awk
MKDIR=/bin/mkdir
TR=/usr/bin/tr

# Cap the injected payload. A long style guide should not dominate the session
# window, and a runaway file should not break the turn at all.
MAX_BYTES=12000

noop() {
  printf '%s\n' '{"continue": true}'
  exit 0
}

# Escape a file's contents for embedding in a JSON string. Three stages:
#   1. Strip every control character except tab and newline. A raw control byte
#      inside a JSON string is invalid, and _internal/ is a directory the user
#      owns, so it may contain CRLF line endings or, at worst, something binary.
#      Fuzzing random input caught this: without the strip, most inputs produced
#      unparseable output.
#   2. Escape backslashes first, then quotes, then tabs. Order matters, or the
#      later escapes get double-escaped.
#   3. Fold newlines last, via awk's output record separator, which sidesteps the
#      awk gsub replacement-string ambiguity around backslashes.
json_escape_file() {
  "$HEAD" -c "$MAX_BYTES" "$1" \
    | "$TR" -d '\000-\010\013-\037\177' \
    | "$SED" -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' \
    | "$AWK" 'BEGIN { ORS = "\\n" } { print }'
}

json_escape_string() {
  printf '%s' "$1" | "$TR" -d '\000-\010\013-\037\177' | "$SED" -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

emit_context() {
  printf '{"additionalContext":"%s"}\n' "$1"
}

STDIN_JSON=$("$CAT" 2>/dev/null || true)

json_field() {
  printf '%s' "$STDIN_JSON" \
    | "$SED" -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | "$HEAD" -n 1
}

REPO=$(json_field cwd)
if [ -z "${REPO:-}" ] || [ ! -d "$REPO" ]; then
  REPO=${PWD:-.}
fi

# Job 0: is this a coco-notes repo at all? If not, the user is working on
# something else entirely and must not be nagged. This is the common case, and it
# fires on every prompt, so it has to stay cheap and silent.
if [ ! -f "$REPO/COCO.md" ] || [ ! -d "$REPO/_internal" ]; then
  noop
fi

MARKER="$REPO/_internal/.coco-notes-setup"
STYLE="$REPO/_internal/writing-style.md"
PROFILE="$REPO/_internal/user-profile.md"

# Per-session state, so the full guide is injected once rather than every turn.
# Keyed by session id, or the hook would bleed across concurrent sessions. If the
# host gives us no session id, degrade to injecting the short reminder only: that
# is wrong in the harmless direction, whereas assuming "first prompt" every time
# would re-send the whole guide on every turn.
SESSION_ID=$(json_field session_id)
STATE_DIR="${TMPDIR:-/tmp}/coco-notes-hook-state"
"$MKDIR" -p "$STATE_DIR" 2>/dev/null || true

first_prompt=no
if [ -n "${SESSION_ID:-}" ]; then
  # Reduce the id to a filename-safe token.
  _key=$(printf '%s' "$SESSION_ID" | "$SED" 's/[^A-Za-z0-9_-]/_/g' | "$HEAD" -c 64)
  STATE_FILE="$STATE_DIR/$_key"
  if [ ! -f "$STATE_FILE" ]; then
    first_prompt=yes
    : > "$STATE_FILE" 2>/dev/null || true
  fi
fi

# Job 1: has setup completed?
#
# The marker is the signal, but it only exists for repos scaffolded by a version
# of this plugin that writes it. A repo set up before then is fully configured and
# has no marker, so testing the marker alone would nag every existing user and,
# worse, skip the injection below for exactly the people who have a personalised
# style guide to inject.
#
# So fall back to evidence: a writing-style.md that is not the shipped placeholder
# means someone completed the interview, whatever version did it. The placeholder
# has carried this sentinel line since 0.1.0.
PLACEHOLDER_SENTINEL="Placeholder style guide"

setup_done=no
if [ -f "$MARKER" ]; then
  setup_done=yes
elif [ -f "$STYLE" ] && ! "$GREP" -q "$PLACEHOLDER_SENTINEL" "$STYLE" 2>/dev/null; then
  setup_done=yes
fi

if [ "$setup_done" = no ]; then
  # Say this once per session, not on every prompt.
  [ "$first_prompt" = yes ] || noop
  emit_context "coco-notes: this looks like a notes repo, but setup has not completed: no _internal/.coco-notes-setup marker, and no personalised writing-style guide. Tell the user their coco-notes install is incomplete and to run /coco-notes:note-setup in this folder to finish it. Until then, do not draft prose in a guessed voice: the writing-style guide is still the generic placeholder. The full runbook is in SETUP.md at the plugin root."
  exit 0
fi

if [ "$first_prompt" != yes ]; then
  # Later prompts: a short reminder, so the style survives skill loads and
  # compaction without re-sending the whole guide.
  emit_context "coco-notes [silent]: the user's writing-style guide at $(json_escape_string "$STYLE") governs every piece of prose you draft for them. It was supplied in full earlier this session; if you no longer have it, read the file before drafting. Surface nothing about this unless it yields a real action."
  exit 0
fi

# First prompt of the session: supply the rules in full.
PAYLOAD="coco-notes [silent]: context loaded from $(json_escape_string "$REPO"). The following is the user's own profile and writing-style guide. Apply the writing style to every piece of prose you draft for them, in this session and in any coco-notes skill you run. Do not summarise or discuss this block; just follow it.\\n"

append_file() {
  _label=$1
  _path=$2
  [ -f "$_path" ] || return 0
  _body=$(json_escape_file "$_path")
  PAYLOAD="$PAYLOAD\\n--- $(json_escape_string "$_label") ---\\n$_body"
  _size=$("$WC" -c <"$_path" 2>/dev/null | "$SED" 's/[^0-9]//g')
  if [ -n "${_size:-}" ] && [ "$_size" -gt "$MAX_BYTES" ]; then
    PAYLOAD="$PAYLOAD\\n[truncated at $MAX_BYTES bytes of $_size. Read $(json_escape_string "$_path") directly if you need the rest.]\\n"
  fi
}

append_file "Writing style" "$STYLE"
append_file "User profile" "$PROFILE"

emit_context "$PAYLOAD"

exit 0

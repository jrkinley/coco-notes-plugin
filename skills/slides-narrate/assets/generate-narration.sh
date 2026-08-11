#!/usr/bin/env bash
# Generate ElevenLabs narration for a PechaKucha HTML deck.
# Single British voice (Daniel, British Broadcaster). One mp3 per slide.
#
# The API key is NEVER stored in this file. It is read only from the
# environment variable ELEVENLABS_API_KEY, which must hold the real key in this
# process's environment at run time. How it gets there is environment-specific
# (e.g. a CoCo build's secret injection). Do not hardcode, commit, or echo the
# value. Verify it resolved first with a length check: echo "len=${#ELEVENLABS_API_KEY}"
#
# Safe to commit: contains no secrets.
#
# Requires: curl, jq. Writes to ../assets/audio (relative to this script).
# Pass slide numbers to regenerate only those (e.g. ./generate-narration.sh 3 4 7).
# With no args, generate all slides.

set -euo pipefail

if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
  echo "ERROR: ELEVENLABS_API_KEY is not set. Run via:"
  echo "  cortex secret run --map elevenlabs_api_key=ELEVENLABS_API_KEY -- ./generate-narration.sh"
  exit 1
fi

VOICE_ID="onwK4e9ZLuTAKqWW03F9"   # Daniel - British Broadcaster
MODEL_ID="eleven_multilingual_v2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/../assets/audio"
mkdir -p "$OUT_DIR"

# One quoted string per slide, in slide order. Write for the ear.
# British English, no em dashes, no emojis. Aim for <= 18s per clip so there is
# a 1-2s pause before the slide auto-advances (PK guideline is 20s; 18s leaves the gap).
scripts=(
"First slide narration goes here. Keep it short so the slide has a moment to breathe before it advances."
"Second slide narration goes here."
)

only=" $* "

i=1
for text in "${scripts[@]}"; do
  if [ "$#" -gt 0 ] && [[ "$only" != *" $i "* ]]; then i=$((i+1)); continue; fi
  out="$OUT_DIR/slide-$i.mp3"
  echo "Generating slide $i ..."
  body="$(jq -n --arg text "$text" --arg model "$MODEL_ID" \
    '{text:$text, model_id:$model, voice_settings:{stability:0.65, similarity_boost:0.85, style:0.10, use_speaker_boost:true, speed:0.96}}')"
  http_code="$(curl -sS -w '%{http_code}' -o "$out" \
    -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" \
    -H "Accept: audio/mpeg" \
    -H "Content-Type: application/json" \
    -d "$body")"
  if [ "$http_code" != "200" ]; then
    echo "ERROR: slide $i failed (HTTP $http_code). Response body:"
    cat "$out"; echo
    rm -f "$out"
    exit 1
  fi
  echo "  saved $out"
  i=$((i+1))
done

echo "Done. Generated $((i-1)) narration clips in $OUT_DIR"

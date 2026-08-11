---
name: slides-narrate
description: "Generate per-slide voiceover narration with ElevenLabs TTS for HTML decks, using a keyless generator script and a single British executive voice. Use when: adding narration or voiceover to a deck, generating slide audio, ElevenLabs TTS, text-to-speech for slides, regenerating a narration clip, timing a clip to fit a slide. Triggers: narration, voiceover, ElevenLabs, TTS, text to speech, slide audio, generate narration, mp3 per slide."
---

# ElevenLabs Narration (per-slide voiceover)

Generate one mp3 per slide with ElevenLabs, for a PechaKucha-style HTML deck whose slides auto-advance when each clip ends (see the `slides-build` skill). Uses a single, measured British voice and a generator script that reads the API key **only from the `ELEVENLABS_API_KEY` environment variable**, so the key is never written to disk or into the script.

**How that variable gets populated is environment-specific and this skill does not prescribe it.** In a CoCo build with working secret injection, the bash tool resolves it from the secret store; in another environment it may come from the surrounding process environment. The skill's only hard requirement is: `ELEVENLABS_API_KEY` must hold the real key in the generator's environment at run time, and the value must never be hardcoded, committed, or pasted into chat. See the `cortex-secrets` skill for the secure-handling rules.

## When to use

You have per-slide narration scripts and want natural-sounding voiceover clips (`assets/audio/slide-N.mp3`) that the deck plays and auto-advances on.

## Key facts (defaults that work)

- **Voice:** Daniel, British Broadcaster, voice id `onwK4e9ZLuTAKqWW03F9`. Calm, measured, executive.
- **Model:** `eleven_multilingual_v2`. Note: v2 does **not** support bracket/SSML-style tags; punctuation is what drives prosody. Use commas, colons, and full stops to control pacing. An exclamation mark lifts the final line.
- **Voice settings:** `stability 0.65, similarity_boost 0.85, style 0.10, use_speaker_boost true, speed 0.96`. The slightly-below-1 speed reads as considered rather than rushed.
- **Output:** `assets/audio/slide-N.mp3`, one per slide, indexed in slide order.

## Pacing: aim for 18 seconds, leave a pause

The deck advances the moment a slide's clip ends, so clip length is the pace control. The PK guideline is 20 seconds per slide, but a clip that runs right up to 20s leaves **no gap between slides**, which sounds forced and artificial.

**Default target: 18 seconds maximum per clip**, leaving a natural 1 to 2 second pause before the slide auto-advances. That breath between slides is what makes the presentation feel composed rather than rushed.

- Roughly 40 to 50 spoken words lands near 18 seconds at speed 0.96.
- **If a clip exceeds 18 seconds, flag it to the user** and offer to shorten the script (give a few concise options). This is a prompt, not a rule: if they are happy to proceed with a longer clip, that is fine.
- If a slide "moves too quickly with no pause", the clip is too close to the slide's dwell time; shorten the script.

Check duration after generating (macOS `afinfo`, or `ffprobe` on Linux/cross-platform):
```bash
# macOS
afinfo assets/audio/slide-2.mp3 | grep -i "estimated duration"
# cross-platform (ffmpeg)
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 assets/audio/slide-2.mp3
```

## Prerequisites

- `curl` and `jq` installed. For duration checks, `afinfo` (macOS, built in) or `ffprobe` (via ffmpeg, cross-platform).
- The ElevenLabs API key available to the generator as the env var `ELEVENLABS_API_KEY` at run time. The generator reads it only from there; it is never written into the script.

**Providing the key securely:** store it in CoCo's secret store (via the `/secrets` slash command where available, user scope) so a build with working injection can supply it. Never tell the user to paste it in chat or commit it. Whether a given build actually injects the stored secret varies (see Troubleshooting); the skill depends only on `ELEVENLABS_API_KEY` being set for the run, not on any one injection mechanism.

## Workflow

### Step 1: Place the generator

Copy `assets/generate-narration.sh` into the deck's `tools/` folder (next to `index.html`'s parent). It writes clips to `../assets/audio`. Make it executable: `chmod +x tools/generate-narration.sh`.

### Step 2: Set the scripts

Edit the `scripts=( ... )` array in the generator: one quoted string per slide, in slide order. Write for the ear, not the eye. Follow the deck house style: British English, no em dashes, no emojis. Spell tricky terms phonetically if the voice mispronounces them (e.g. write acronyms as "A.D.E." to force letter-by-letter delivery).

### Step 3: Confirm the voice

Before generating, ask the user (use the question tool) which voice to use:
- **Default:** Daniel, British Broadcaster (`onwK4e9ZLuTAKqWW03F9`). Calm, measured, executive. This is the default; keep it unless the user chooses otherwise.
- **Alternate:** the user supplies an ElevenLabs voice id (from their ElevenLabs account or the voice library). Set `VOICE_ID` in the generator to that id before running.

Use one voice across the whole deck so it sounds like a single narrator. Prompt once per deck and reuse the chosen voice for any regenerated slides.

### Step 4: Generate

Run the generator with `ELEVENLABS_API_KEY` set in its environment. Pass slide numbers to regenerate only those; no args regenerates all:
```bash
cd tools
./generate-narration.sh 2         # one slide
./generate-narration.sh 3 4 7     # several
./generate-narration.sh           # all
```
The script fails fast with a clear message if `ELEVENLABS_API_KEY` is unset, so it never writes a broken clip.

**Supplying the key is environment-specific.** In a CoCo build with working secret injection, the agent injects the stored secret into the command's environment (for example the bash tool's `secret_env` parameter mapping `ELEVENLABS_API_KEY` to the stored key name). The mechanism is not guaranteed across builds, so **verify it actually resolved before generating** (length only, never print the value):
```bash
echo "len=${#ELEVENLABS_API_KEY}"   # a real key is dozens of chars; 0 means not injected
```
If the length is 0, or the value equals the literal secret key name, the build is not resolving the secret. Do not proceed: generate in an environment where `ELEVENLABS_API_KEY` is populated with the real key (see Troubleshooting). Whatever the mechanism, the value must never be hardcoded, committed, or echoed.

### Step 5: Verify duration and iterate

Check each regenerated clip's duration. **If any exceeds 18 seconds, flag it to the user** and offer to trim (a few concise options), so there is a 1 to 2 second pause before the slide advances. Let them override and keep a longer clip if they prefer. Regenerate only the slides you change.

## Tools

### Script: generate-narration.sh

**Description:** POSTs each slide's text to the ElevenLabs text-to-speech API and saves `slide-N.mp3`. Reads the key only from `ELEVENLABS_API_KEY`; exits with a clear error if it is unset. On any non-200 response it prints the API error body and stops, so a failure never leaves a broken clip.

**Run:** run with `ELEVENLABS_API_KEY` present in the environment. Supply it through your build's secret mechanism; never hardcode, commit, `export` a literal value into a shared shell, or echo it. Verify it resolved with a length check before generating (see Step 4).

**Edit points:** `VOICE_ID`, `MODEL_ID`, the `voice_settings` in the `jq` line, and the `scripts=()` array.

**Changing the narrator:** the default `VOICE_ID` is Daniel (British Broadcaster). To use a different narrator, pick a voice in the ElevenLabs voice library and replace `VOICE_ID` with its id. Keep one voice across the whole deck so it sounds like a single narrator.

## Troubleshooting

**The key is not reaching the script (401 from ElevenLabs, or the script's "ELEVENLABS_API_KEY is not set" error).** Probe the injected value length only, never print it: `echo "len=${#ELEVENLABS_API_KEY}"`.

- **Length is 0 (empty), or the value equals the literal secret key name.** The running build is not resolving the stored secret into the environment. Secret injection support varies by CoCo build: it worked on v1.0.74, but v1.1.49 was observed **not** to inject (the `secret_env` parameter returned empty and the inline `VAR="<key-name>"` form passed the literal name through), and `/secrets` was absent there. There is also **no `cortex secret run` subcommand** in current builds (`cortex secret` only has `store`, `list`, `delete`, `purge`). Fix: generate on a build where injection works, or otherwise ensure `ELEVENLABS_API_KEY` holds the real key in the generator's environment. Never work around this by committing or pasting the value.
- **Length looks right but still 401.** Check the key itself (rotated/revoked) and that `cortex secret list` shows the expected entry.
- **Consent gate.** Where injection is supported, user-scope secrets may use the `once` consent mode (a first-use approval prompt per session); if unsatisfied the resolver can return empty. Satisfy the prompt or set the consent mode via `/secrets`.

## Output

`assets/audio/slide-N.mp3` for each slide, wired into the deck's `narratorAudio` array (see `slides-build`).

## Notes

- The script is safe to commit: it contains no secrets.
- Keep the voice and settings consistent across all slides so the deck sounds like one narrator.
- Regenerate only the slides you changed; it is faster and avoids drifting clip lengths on untouched slides.

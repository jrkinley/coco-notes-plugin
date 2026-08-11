---
name: slides-build
description: "Build cinematic, single-file HTML PechaKucha (PK) pitch decks for customer proposals, styled to Snowflake branding with audio-driven auto-advance. Entry point that orchestrates narration and deployment. Use when: building a slide deck, pitch deck, PechaKucha, customer proposal presentation, or an HTML deck with voiceover. Triggers: pechakucha, PK, pitch deck, slide deck, proposal slides, HTML deck, cinematic deck, timed slides, auto-advance slides."
---

# PechaKucha Slides (Snowflake-branded HTML decks)

Build a self-contained, single-file `index.html` PechaKucha deck: full-screen slides, keyboard navigation, and optional voiceover that auto-advances when each slide's narration clip ends. No build step, no framework, no external JS.

This is the **entry point** for making narrated decks. It orchestrates two companion skills:
- `slides-narrate` generates the per-slide voiceover (optional, can be skipped).
- `slides-deploy` hosts the finished deck on Snowflake SPCS (only if the user chooses to deploy).

## What is PechaKucha (PK)?

PechaKucha is a Japanese presentation format ("chit-chat") designed for crisp, engaging executive storytelling. The classic discipline is **20 slides, 20 seconds each** (about 6 minutes 40): tight visuals, few words, one idea per slide, and a steady auto-advancing rhythm so the story keeps moving.

**Treat PK as a guideline, not a rule.** It produces excellent, disciplined decks, so default to it. But real executive presentations sometimes need more than 20 slides, or a slide that needs longer than 20 seconds to land. When the user wants to exceed either limit, **do not block them**: note that it departs from PK best practice, confirm they want to continue, and proceed. The point is to nudge toward tight storytelling, not to enforce it.

Apply this when:
- The deck exceeds 20 slides, or
- A narration clip runs longer than ~20 seconds (see `slides-narrate`).

In both cases, flag it once as a friendly warning and let the user override.

## House style (non-negotiable defaults)

These reflect how the author works. Keep them unless the user overrides:

- **Snowflake cyan** is the accent (`#29B5E8`). Never purple.
- **British English** throughout (optimisation, prioritise, behaviour).
- **No em dashes.** Use commas, colons, or full stops instead.
- **No arrows in prose** (no `->`, no unicode arrows in body copy). Arrows are fine only inside diagrams if truly needed.
- **No emojis** in slide copy.
- **Pharma-cinematic / executive tone:** measured, confident, concrete. Short lead lines, big metrics, minimal words per slide.
- Metrics should be few and large. Two or three big numbers beat a wall of stats.

## Assets: customer assets vs Snowflake marks

**Customer logos and background images: never source them yourself.** Never generate, invent, download, or guess at a customer brand mark or photo. Always **ask the user to provide** customer logos and any background photography. Reasons: brand accuracy, licensing, and trust.

- If the user provides logos/backgrounds, place them in `assets/` and reference them.
- If the user has none yet, use the **built-in branded CSS gradient fallbacks** (`.bg-title/.bg-a/.bg-b/.bg-c/.bg-cta`) so the deck still looks finished, and offer to whiten a provided SVG/PNG logo to match once they supply one.
- Gradient fallbacks are the only acceptable stand-in. Do not substitute stock or generated imagery.

**Snowflake brand marks: always bundled, always placed the same way.** The skill ships the two Snowflake marks in its own `assets/` folder (`snowflake-logo-reverse.png`, `snowflake-bug-reverse.png`). Copy both into every new deck's `assets/` and always use them in these fixed positions. This is house style, not optional, and it is the one logo case the skill does source itself (they are Snowflake's own marks, not a customer's):

- **`snowflake-logo-reverse.png`** sits in the **title slide eyebrow**, inside the `.cobrand` row, paired with the customer logo and a separator (`customer logo | Snowflake`). Title slide only.
- **`snowflake-bug-reverse.png`** is fixed in the **bottom-right corner of every slide** via the `.logo-sf` element. It lives outside `.deck`, so it shows on all slides automatically.
- Keep the `onerror` text fallback on both `<img>` tags so a missing file never breaks a slide, but the files should always be present in `assets/`.

## Deck mechanics (the contract)

- **~20 seconds per slide (PK guideline).** When narrated, the slide advances the instant its audio clip ends, so clip length sets the pace. Target under 20s; a shorter clip creates a natural pause before advancing. Longer is allowed with a PK warning (see above).
- **One narration clip per slide**, named `assets/audio/slide-N.mp3`, held in a `narratorAudio` array in slide order.
- **Controls:** Left / Right arrows navigate; `Space` or `N` toggles voiceover; `F` fullscreen; `H` home. A visible control bar mirrors these.
- **Auto-advance** only while narration is on, and it **stops on the last slide** (no loop). Manual arrow nav always works; arriving at a slide while narration is on plays that slide's clip.
- **Counter** shows `NN / TOTAL`; a progress bar tracks position.

## Structure

```
<deck-name>/
  index.html            # the entire deck (HTML + CSS + JS inline)
  assets/
    <bg>.jpeg           # slide background photo(s) - user-provided only
    snowflake-logo-reverse.png  # bundled Snowflake mark - title-slide eyebrow
    snowflake-bug-reverse.png   # bundled Snowflake mark - fixed bottom-right, every slide
    <customer-logo>.svg|png     # customer logo - user-provided only
    audio/slide-N.mp3   # one narration clip per slide
```

## Workflow

### Step 1: Gather the essentials

Ask the user (use the question tool) for anything not already known:
- Customer name and the single outcome the deck must sell.
- Number of slides. Default toward the PK guideline of up to 20; if they want more, note it departs from PK and proceed.
- **Logos and background images.** Prompt the user to provide these. Never source them yourself. If none are available, proceed with gradient fallbacks and revisit logos later.

### Step 2: Draft the narrative arc first, in prose

Before touching HTML, write the one-line-per-slide arc and get sign-off. A proven arc for an FDE/ADE-style pitch:
1. Title / the one outcome
2. Market shift (external proof, e.g. analyst data)
3. The opportunity (the customer's target metric)
4. The core concept (the "big idea" hero slide)
5. Proof (we already do this)
6. Trust / staged rollout
7-9. The workstreams / how it lands
10. The ask / where we start

Keep it flexible; the point is a clear beginning, proof in the middle, and a concrete ask at the end.

### Step 3: Build `index.html` from the scaffold

Copy `assets/scaffold.html` to `index.html` and add one `<section class="slide">` per slide. Key pieces are reproduced under "The scaffold" below so you can build without loading the asset.

Also copy the two bundled Snowflake marks from the skill's `assets/` into the deck's `assets/`: `snowflake-logo-reverse.png` (title-slide eyebrow) and `snowflake-bug-reverse.png` (fixed bottom-right on every slide). The scaffold already references both; see "Snowflake brand marks" above for placement.

### Step 4: Refine the copy (suggest, then apply)

Slides start too wordy. Tighten iteratively: when a lead or note is long, **offer about three concise alternatives via the question tool and let the user choose**, rather than rewriting unilaterally. Propose changes first and apply on approval; this is how the author prefers to work. To draw the eye to a single phrase, wrap it in an inline cyan span, e.g. `<strong style="color:var(--sf-cyan)">key phrase</strong>` (distinct from the `.highlight` gradient used on headings).

### Step 5: Visual review

Open the file and click through; verify the Snowflake logo shows in the title-slide eyebrow and the Snowflake bug sits bottom-right on every slide, metrics sit side by side, logos are legible, links are centred, and the house style holds (cyan not purple, British English, no em dashes, no arrows, no emojis).

### Step 6: Offer narration (skippable)

Once the slides are reviewed, **prompt the user: generate narration now, or skip?**
- If yes: load `slides-narrate`, pass the per-slide scripts, generate clips, and confirm each is within the PK ~20s guideline (warn and allow override if longer). Then wire the `narratorAudio` array and set the counter default to `01 / NN`.
- If skip: leave the deck silent. The `narratorAudio` array can stay empty or partial; the deck still navigates by keyboard. The skill must handle a deck with no audio gracefully.

### Step 7: Offer deployment (user's choice)

Finally, **ask the user whether they want to deploy**.
- If yes: load `slides-deploy` and run its workflow (build, push, service create/update, grants).
- If no: stop. Leave the deck local.

**Deploy and any git commit are gated on explicit user approval.** Do not deploy or commit without it.

## Editing an existing deck

Much of the work is surgical edits to a finished deck, not building from scratch. When editing:
- Read the current `index.html` before changing it.
- Inserting or removing a slide means keeping three things in sync: the slide `<section>`s, the numbered slide comments (renumber them), and the `narratorAudio` array plus the counter default (`NN / TOTAL`).
- If a slide's on-screen copy changes in a way that affects the voiceover, regenerate only that slide's clip via `slides-narrate`.
- Keep proposing changes first and applying on approval.

## The scaffold

The full working base deck (head, CSS system, one title slide, controls, and the nav/narration script) is in `assets/scaffold.html`. Key pieces:

**CSS colour tokens (`:root`):**
```css
--sf-cyan:#29B5E8; --sf-dark-blue:#11567F; --sf-deep:#0A2540;
--sf-ice:#E8F4FD; --sf-light-cyan:#7DD3F0; --sf-accent:#1DA1D4;
--bg-0:#04121f; --text:#eef6fd; --text-soft:rgba(238,246,253,0.66);
```

**Slide + background system:** each slide is
```html
<section class="slide bg-a" data-bg>
  <div class="slide-bg" style="--img:url('assets/bg.jpeg')"></div>
  <div class="overlay"></div>
  <div class="slide-content"> ... </div>
</section>
```
`.bg-title/.bg-a/.bg-b/.bg-c/.bg-cta` are branded gradient fallbacks; `.overlay` is a dark readability wash so text stays legible over any photo.

**Reusable content classes:** `.label` (cyan eyebrow), `h1`/`h2`, `.highlight` (cyan gradient text), `.hl-u` (cyan underline), `.divider`, `.lead` (sub-text), `.note` (+ `.note strong` in light cyan), `.stat-row`/`.stat-block`/`.stat-n`/`.stat-l` (big metrics), `.reflink` (source link pills), `.callout`, `.grid-2`/`.grid-3`/`.card`, `.cobrand` (logo row).

**Two metrics side by side:** constrain each block, e.g.
```html
<div class="stat-block" style="flex:1;min-width:240px;max-width:400px">...</div>
```
Without a max-width, long labels make blocks stretch and wrap to a stacked layout.

**Whiten a user-provided SVG or PNG logo to match the deck:**
```html
<img src="assets/logo.svg" style="filter:brightness(0) invert(1);opacity:0.92">
```
Provide a text fallback via `onerror` so a missing file never breaks the slide.

**The navigation + narration script** (drop in before `</body>`):
```html
<script>
var slides=Array.from(document.querySelectorAll('.slide'));
var TOTAL=slides.length, cur=0;
var progress=document.getElementById('progress');
var counter=document.getElementById('counter');
var narrateBtn=document.getElementById('narrateBtn');
var narratorAudio=[ 'assets/audio/slide-1.mp3' /* ...one per slide, in order; may be empty if narration skipped... */ ];
var narrating=false, audioEl=null;
function pad(n){return (n<10?'0':'')+n;}
function render(){
  slides.forEach(function(s,i){s.classList.toggle('active',i===cur);});
  if(progress) progress.style.width=((cur+1)/TOTAL*100)+'%';
  if(counter) counter.textContent=pad(cur+1)+' / '+pad(TOTAL);
}
function go(i){cur=(i+TOTAL)%TOTAL;render(); if(narrating) playCurrentClip();}
function next(){go(cur+1);} function prev(){go(cur-1);} function home(){go(0);}
function playCurrentClip(){
  if(!narratorAudio[cur]){ return; }        // no clip for this slide (narration skipped): stay put
  if(audioEl){audioEl.pause();}
  var a=new Audio(narratorAudio[cur]); audioEl=a;
  a.addEventListener('ended',function(){
    if(!narrating || a!==audioEl) return;   // ignore stale/paused clips
    if(cur < TOTAL-1){ go(cur+1); }          // stop on last slide, no loop
  });
  var p=a.play(); if(p && p.catch) p.catch(function(){});
}
function stopNarration(){narrating=false;narrateBtn.classList.remove('on');if(audioEl){audioEl.pause();audioEl=null;}}
function toggleNarration(){ if(narrating){stopNarration();return;} narrating=true;narrateBtn.classList.add('on');playCurrentClip(); }
function toggleFS(){ if(!document.fullscreenElement) document.documentElement.requestFullscreen(); else document.exitFullscreen(); }
document.addEventListener('keydown',function(e){
  if(e.key==='ArrowRight'){next();}
  else if(e.key==='ArrowLeft'){prev();}
  else if(e.key===' '||e.key.toLowerCase()==='n'){e.preventDefault();toggleNarration();}
  else if(e.key.toLowerCase()==='f'){toggleFS();}
  else if(e.key.toLowerCase()==='h'){home();}
});
render();
</script>
```

## Output

A single `index.html` plus `assets/`, optionally narrated (`slides-narrate`) and optionally hosted (`slides-deploy`).

## Notes

- Keep it one file with inline CSS/JS. No CDNs, no build. It must open and run offline.
- Prefer few words and large metrics per slide; the voiceover carries the detail.
- PK is a guideline: nudge toward 20 slides and 20s clips, warn on override, never force.
- Never source logos or backgrounds; always ask the user to provide them.

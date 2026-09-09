# Brand assets

A local cache of brand assets — logos, wordmarks, background imagery — downloaded from wherever your
organisation publishes them. For Snowflake, that is https://www.snowflake.com/brand-guidelines/.

**Contents are deliberately not tracked in git.** Everything here is re-downloadable from source, so
committing it only adds weight to the repo. This README is the only tracked file in the folder.

Decks do not reference this folder. Each deck is self-contained, with asset paths relative to the deck
itself, because a deck may be copied elsewhere or containerised and deployed on its own. A cross-folder
reference like `../../brand/logo.svg` breaks the moment that happens.

So the flow is: download once into here, then copy the file into the deck's own `assets/`. This folder
saves you the download, not the copy.

If an asset is missing, fetch it from source. Do not improvise logo files, colour codes, or typography
from memory.

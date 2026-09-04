# Omarchy Font

The Omarchy wordmark as a real, installable font. Type anything and get the
block-built letters of the logo.

**Source:** [markcuda/Omarchy-Font](https://github.com/markcuda/Omarchy-Font)
**Specimen and live preview:** <https://tinker.markcuda.com/omarchy-font/>
**Licence:** MIT, Copyright (c) 2026 Mark Cuda

A copy is vendored here at [`font/Omarchy Font.ttf`](../font/Omarchy%20Font.ttf)
with its licence alongside it, so the install works offline and pins a known
version. Upstream is the place to get the newest one.

## What you get

- The seven letters of the wordmark (**O M A R C H Y**) match Omarchy's
  official `logo.svg` pixel for pixel. Typing `OMARCHY` reproduces the logo
  exactly, spacing included.
- The other nineteen letters are condensed from *Delta Corps Priest 1*, the
  FIGlet font the wordmark grew out of, using the same rules the wordmark
  applies: three-cell strokes, three-cell counters, half-block corners.
- Digits and all ASCII punctuation, drawn to match. The FIGlet original has
  none.
- Unicase: lowercase renders as capitals. 7 KB.
- Cells are 1:2 like a terminal, and every glyph is a single merged outline, so
  there are no seams between rows at any size.

## Install

`./install.sh` installs it by default. Skip it with `./install.sh --no-font`.

By hand:

- **Linux:** copy the TTF to `~/.local/share/fonts/` and run `fc-cache -f`
- **macOS / Windows:** double-click the file, then click *Install*

On the web:

```css
@font-face {
  font-family: "Omarchy Font";
  src: url("Omarchy Font.ttf") format("truetype");
}
```

## How it relates to the terminal banner

These are two renderings of the same letterforms, and it is worth being clear
about which is which, because they are not interchangeable.

| | Omarchy Font | The banner in this repo |
|---|---|---|
| Format | TrueType outlines | Unicode half-block text |
| Where it works | GUI apps, web, anything that takes a font | Any terminal, over SSH, in logs |
| Arbitrary text | Yes, type anything | No, fixed art |
| Colour | Whatever the app does | Per-column gradient |

The banner cannot use the TTF: a terminal renders text in its own monospace
font, and it has no way to switch face mid-line. So the banner stays as block
art built from Omarchy's `logo.txt`, and the font covers everywhere a real font
can be used. Both trace back to the same source, which is why they match.

If you want the wordmark somewhere that takes a font, a heading, a slide, a
terminal title bar, a login screen, this is the one to use.

## The case for shipping it with Omarchy

Omarchy already treats the wordmark as part of the system. It ships `logo.svg`,
generates `logo.txt` from it with `omarchy-transcode-ascii`, prints it from
`omarchy-show-logo`, and puts it on the Plymouth boot screen and the SDDM login
screen. Every one of those is the same seven letters, rebuilt for a different
medium each time.

What is missing is the medium a desktop uses most: a font. Right now anything
outside those hardcoded assets, a heading, a theme, a slide, a window title, a
generated graphic, has to fall back to a bitmap of the logo or to some other
typeface entirely.

Shipping the font would close that gap, and the practical case is small:

- **It is 7 KB.** Smaller than any single icon in `applications/icons/`.
- **The install already places fonts.** Omarchy installs Nerd Fonts as part of
  setup, so `~/.local/share/fonts` plus `fc-cache` is a path the installer
  already walks.
- **It is MIT**, so there is no licensing obstacle to redistribution.
- **It is derived from `logo.svg` itself**, so it cannot drift from the brand;
  the seven wordmark letters are the logo, not an approximation of it.
- **Updates are free.** Once the file is in the install manifest, `omarchy
  update` carries new versions with everything else.

The honest counter-arguments: it is a third-party fan project rather than
something 37signals maintains, so it would need adopting rather than merely
linking; and a font is a brand asset, which makes shipping it a decision about
the wordmark, not just about bytes. Both are reasons to ask first, not reasons
it is a bad idea.

Until then, this repo installs it for you.

## Credits

- **omarchy-dotfiles**, the shell setup that packages and installs this font, is
  customised by **James Tervit**, and given freely to Omarchy.org and DHH to
  install, ship or exploit as they wish. The Omarchy name and wordmark are the
  property of Omarchy.org, DHH and 37signals, all rights reserved.
- **Omarchy** is by [DHH](https://dhh.dk) and 37signals: <https://omarchy.org>
- **Delta Corps Priest 1**, the FIGlet font the letterforms grew out of, is by
  CoSMiC cHiLD
- **Omarchy Font** is a fan project by
  [Mark Cuda](https://x.com/therealmc92), not affiliated with either. The
  Omarchy name and wordmark remain 37signals'.

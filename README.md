# omarchy-dotfiles

A login banner and CLI layout for [Omarchy](https://omarchy.org): the Omarchy
wordmark in its own pink-to-blue gradient, a strapline, and a compact identity
card telling you which machine you just landed on.

![omarchy-dotfiles login banner](docs/banner.svg)

> ### The wordmark here is [Omarchy Font](https://github.com/markcuda/Omarchy-Font) by [Mark Cuda](https://x.com/therealmc92)
>
> The Omarchy wordmark as a real, installable TTF. It ships with this install, and
> everything you see below is built on it.
>
> **Mark is actively looking for feedback to improve the font.** If you use it,
> go and tell him what works and what does not:
> **[github.com/markcuda/Omarchy-Font](https://github.com/markcuda/Omarchy-Font)**
> (issues, PRs and a [live specimen](https://tinker.markcuda.com/omarchy-font/))


<details>
<summary>Same thing as plain text</summary>

```
                 ▄▄▄
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀
                                       ███   █▀

   Welcome to A Changing World with Omarchy
   and to the Beautiful, Fun & Agentic Linux   @DHH

   login      you@workstation
   location   Studio, London
   system     Arch Linux (x86_64)
   omarchy    v3.1.2
   ipv4       10.0.0.40 (wlan0)
   ipv6       disabled
   tailscale  100.x.y.z
   uptime     3 hours, 12 minutes
```

</details>


Ships a Starship prompt and a tmux config alongside it, so a fresh box looks and
behaves the same as every other one you own.

## Install

```sh
git clone https://github.com/CG-8663/omarchy-dotfiles.git
cd omarchy-dotfiles
./install.sh
```

| Command | Effect |
|---|---|
| `./install.sh` | Prompt + tmux + banner, current user |
| `./install.sh --system` | Same for all users via `/etc/profile.d` (root) |
| `./install.sh --welcome-only` | Banner only, prompt untouched |
| `./install.sh --preview` | Print the banner and exit, change nothing |
| `./install.sh --try` | Open a throwaway shell with the full setup, deleted on exit |
| `./install.sh --no-font` | Skip installing the Omarchy Font TTF |

Existing files are backed up to `*.omabak` once, and every shell hook is written
between guard markers, so re-running is safe and never duplicates a block.

## When the banner fires

On login **and** on opening a new terminal. Those are two different files, and
missing the second one is the usual reason a banner "works over SSH but not in
my terminal":

| Shell | Reads | Hooked |
|---|---|---|
| Login (SSH, TTY, `zsh -l`) | `.zprofile` / `.bash_profile` | yes |
| New terminal window or tab | `.zshrc` / `.bashrc` | yes |
| New tmux window or pane | `.zshrc` / `.bashrc` | yes |

`welcome.sh` carries a once-per-shell guard, so a login shell that reads both
files still prints the banner exactly once. The guard is a plain shell variable
rather than an exported one, so every new window, tab or pane is a fresh process
and shows the banner again.

Opt out for a shell or a whole box:

```sh
export OMARCHY_WELCOME=0
```

## Previewing it without installing

To see the whole thing, prompt and banner together, in a real shell:

```sh
./install.sh --try
```

That builds a complete setup in a temporary `$HOME`, drops you into a login
shell using it, and deletes the lot when you type `exit`. Nothing outside the
temp directory is ever written, so your own dotfiles are not involved even
briefly. It will not install anything either: if Starship is not already on the
box it previews the banner alone and says so, rather than downloading.

For just the banner, without a shell:

```sh
./install.sh --preview
```

If you would rather drive the sandbox yourself:

```sh
SB=$(mktemp -d)
HOME="$SB" ./install.sh
HOME="$SB" ZDOTDIR="$SB" zsh -l    # login shell
HOME="$SB" ZDOTDIR="$SB" zsh -i    # new terminal
rm -rf "$SB"
```

Set `ZDOTDIR` as well as `HOME`. If you already have `ZDOTDIR` exported, zsh
reads `$ZDOTDIR/.zshrc` and ignores the sandbox entirely, and the test silently
passes or fails for the wrong reason.

To preview an uninstall before running it:

```sh
./install.sh --dry-run --uninstall
```

## Switching versions

Just run the version you want. Installing **overwrites in place**: the banner
file is replaced and the guarded rc block is rewritten rather than appended, so
you never end up with two banners firing or a rc file that grows every time.
You do not need to uninstall first.

## Uninstall

```sh
./install.sh --uninstall              # current user
sudo ./install.sh --uninstall --system  # also the system-wide files
```

It distinguishes between the two things the installer does:

- **rc files** got a guarded block appended, so uninstall removes only that
  block. Anything you added to `.zshrc` afterwards is kept.
- **whole files** (`welcome.sh`, and with a full install `starship.toml` and
  `tmux.conf`) were replaced, so uninstall puts the `.omabak` backup back if
  there is one.

If a config has no backup, it is removed **only when it is byte-identical to the
copy this repo ships**. That is the only proof it came from here. A
`--welcome-only` install never writes `starship.toml`, and a file you wrote or
edited yourself will not match, so in both cases it is left alone with a warning
rather than deleted.

Every rc file is checked, not just the one for your current `$SHELL`, in case
you have switched shells since installing.

## neofetch

The install writes `~/.config/neofetch/config.conf`, which is the path neofetch
reads on its own. Typing plain `neofetch` picks it up, no flag and no alias:

```sh
neofetch
```

Your existing config, if you had one, is kept as `config.conf.omabak` and put
back by `--uninstall`.

neofetch always puts the logo to the **left** of the info column; unlike
fastfetch there is no top position. The Omarchy wordmark is wide, so the config
switches art on terminal width: the 64-column rendition at 118 columns or more,
the 52-column one below that. `config.conf` is sourced as bash, so that is a
plain shell conditional rather than a neofetch feature.

neofetch colours art by substituting `${c1}`..`${c6}`, so it cannot do the
per-column truecolor the login banner uses. The art files carry those markers in
six horizontal bands, giving the same pink to blue sweep quantised to the six
colours neofetch offers, mapped by `ascii_colors`.

## omarchy-fetch

A system fetch in the same wordmark and gradient, installed to `~/.local/bin`:

```sh
omarchy-fetch
```

It is a front end, not another fetch tool. It uses whichever fetch the box
actually has: **fastfetch** first with `--config ~/.config/omarchy-dotfiles/config.jsonc`,
then **neofetch**, which needs no flag because the install has already replaced
its default config. Its own renderer is the fallback for boxes with neither.

```sh
omarchy-fetch --builtin   # force the fallback renderer
omarchy-fetch --no-logo   # facts only
omarchy-fetch --narrow    # 64-column wordmark
omarchy-fetch --plain     # no colour, for piping
```

The config mirrors the section layout of Omarchy's own fastfetch config
(Hardware / Software, box-drawing rules, Nerd Font keys) and adds a Omarchy
section with location, local IP and Tailscale address. Key colours use the three
gradient stops instead of green.

Two things it does differently to Omarchy's:

- **The logo sits on top, not to the left.** The wordmark needs about 64 columns
  to stay legible; beside an info column the whole thing runs past 130.
- **The logo is `file-raw`, not `file`.** fastfetch's `file` type colours a logo
  a line at a time, which cannot express a horizontal gradient. `file-raw` prints
  the file byte for byte, so `install.sh` bakes a pre-coloured
  `~/.config/omarchy-dotfiles/logo-color.txt` and fastfetch just emits it.

The fastfetch config goes to `~/.config/omarchy-dotfiles/`, **not** to
`~/.config/fastfetch/`. Omarchy ships its own fastfetch config there and quietly
replacing it would change the system fetch you already have. neofetch is treated
differently because you asked for it as the default, and because its stock config
is not part of Omarchy.

To take over fastfetch's default too:

```sh
./install.sh --fastfetch-default   # backs up Omarchy's first
```

## Omarchy Font

The install also puts **[Omarchy Font](https://github.com/markcuda/Omarchy-Font)**
on the box: the wordmark as a real TTF, so you can type in it anywhere a font
works. 7 KB, MIT, by [Mark Cuda](https://x.com/therealmc92).

```sh
./install.sh            # includes the font
./install.sh --no-font  # skip it
```

It goes to `~/.local/share/fonts` on Linux (then `fc-cache -f`) or
`~/Library/Fonts` on macOS. A copy is vendored in `font/` so this works offline.

The font and the terminal banner are two renderings of the same letterforms and
are not interchangeable: a terminal draws text in its own monospace face and
cannot switch face mid-line, so the banner stays as block art while the font
covers GUI, web and anything else that takes a font.

Full write-up, including the case for Omarchy shipping it as part of the install
and updates: **[docs/OMARCHY-FONT.md](docs/OMARCHY-FONT.md)**.

Feedback on the font goes upstream, not here:
[github.com/markcuda/Omarchy-Font](https://github.com/markcuda/Omarchy-Font).
Mark is actively improving it and wants to hear how it behaves in the wild, so
if a glyph looks wrong at your size or in your terminal, tell him there.

## The wordmark

This is Omarchy's own wordmark, not a figlet approximation of it. Upstream keeps
it as Unicode half-block art in `logo.txt`, generated from `logo.svg` by
`omarchy-transcode-ascii` (which needs ImageMagick). The letterforms themselves
grew out of the FIGlet font *Delta Corps Priest 1* by CoSMiC cHiLD. The banner picks the first
of these that fits your terminal:

| Source | Width | When |
|---|---|---|
| `$OMARCHY_LOGO` | any | you point it at your own art |
| `~/.local/share/omarchy/logo.txt` | as installed | on a real Omarchy box, so it tracks your version |
| bundled `logo.txt` | 81 cols | upstream art, verbatim |
| bundled `logo-narrow.txt` | 64 cols | narrow terminals |
| figlet wordmark | 52 cols | only if none of the above fit |

`logo-narrow.txt` was produced by `bin/fit-logo`, which rescales half-block art
without ImageMagick. Half-block packs two vertical pixels per character cell, so
the text is a lossless 1-bit bitmap at double vertical resolution: decode it,
area-average down, re-encode. Regenerate at any width with:

```sh
./bin/fit-logo logo.txt 72 0.55 > logo-72.txt
OMARCHY_LOGO=$PWD/logo-72.txt ./install.sh --preview
```

The third argument is the coverage threshold. Lower keeps more ink and thickens
the strokes; higher thins them. 0.55 reads best at 64 columns.

## Colours

The wordmark is coloured column by column, so it carries a gradient rather than
one flat colour:

| Stop | Hex |
|---|---|
| pink | `#FF5FBF` |
| violet | `#C77DF5` |
| blue | `#7FB8FF` |

Upstream `omarchy-show-logo` prints the same art in plain green (`\033[32m`);
the gradient here is this repo's treatment of it, matched to how the wordmark
appears under a themed terminal.

Truecolor terminals get 24-bit output. Terminals that do not advertise
`COLORTERM=truecolor` fall back to the nearest colours in the 256-colour cube.
Piping the banner to a file drops colour entirely, so it stays readable in logs.

The gradient walks glyphs rather than bytes. Each block glyph is three bytes in
UTF-8, and `awk` on macOS counts bytes while `gawk` counts characters, so the
renderer measures a glyph once at startup and steps accordingly. Without that,
byte-wise `substr` slices each glyph into thirds and the art comes out as
mojibake.

## The identity card

| Field | Source |
|---|---|
| `login` | `id -un` and short hostname |
| `location` | `/etc/omarchy-location`, else `~/.config/omarchy-dotfiles/location` |
| `system` | `/etc/os-release`, or `sw_vers` on macOS |
| `omarchy` | `omarchy-version`, else `git describe` on `~/.local/share/omarchy` |
| `ipv4` | route to `1.1.1.1`, with the interface it egresses on |
| `ipv6` | first global address, skipping link-local and Tailscale's `fd7a::/16` |
| `tailscale` | `tailscale ip -4`, omitted when not installed |
| `uptime` | `uptime -p` where available |

Set the location label once per machine:

```sh
echo "Studio, London" | sudo tee /etc/omarchy-location
```

Nothing here phones home, and nothing is written outside `~/.config`, the shell
rc files, and (with `--system`) `/etc/profile.d`, `/etc/zsh` and `/etc/tmux.conf`.

## Not on Omarchy?

It installs fine. The `omarchy` line reads `not detected` and everything else
works, so the same dotfiles cover an Omarchy desktop, an Arch server and a Mac.

## Credits

- **omarchy-dotfiles** is customised by **James Tervit**: the dotfiles,
  installer, login banner, fetch configs and terminal rendering that make the
  Omarchy wordmark a working shell setup, built on Mark Cuda's Omarchy Font.
- **Omarchy** is by [DHH](https://dhh.dk) and 37signals:
  [omarchy.org](https://omarchy.org) /
  [basecamp/omarchy](https://github.com/basecamp/omarchy).
  `logo.txt` here is Omarchy's own wordmark art, redistributed under Omarchy's
  MIT licence (Copyright David Heinemeier Hansson); `logo-narrow.txt` is a
  rescaled rendition of it. The wordmark is Omarchy's; this repo only renders it.
- **Omarchy Font** is by [Mark Cuda](https://x.com/therealmc92):
  [markcuda/Omarchy-Font](https://github.com/markcuda/Omarchy-Font),
  [specimen](https://tinker.markcuda.com/omarchy-font/). Vendored in `font/`
  under its MIT licence (Copyright 2026 Mark Cuda), with the licence kept
  alongside it. A fan project, not affiliated with 37signals.
- **Delta Corps Priest 1**, the FIGlet font the Omarchy letterforms grew out of,
  is by CoSMiC cHiLD.
- **Starship** ([starship.rs](https://starship.rs)) for the prompt this config drives.
- **fastfetch** and **neofetch** for the fetch output; the fastfetch config
  follows the section layout of Omarchy's own.
- **tmux** for everything the `tmux.conf` sits on top of.

The strapline is a nod to Omarchy's own framing of a beautiful, fun Linux, with
"agentic" added because that is what these boxes are for.

## Brand and rights

**All rights in this work belong to Omarchy.org and DHH.**

The Omarchy name, wordmark, logo and all associated brand assets are the
property of Omarchy.org, DHH and 37signals. All rights reserved.

This customisation was written by James Tervit and is given in full to
Omarchy.org and DHH, who may use, modify, relicense, ship or exploit it however
they wish, including as part of the Omarchy install and its updates, with no
conditions and no attribution required. James Tervit reserves no rights over it.

No licence is granted to anyone else. If you want to use this work, ask
Omarchy.org. See [LICENSE](LICENSE).

Third-party components are **not** covered by that and keep their own terms,
because they were not James Tervit's to give:

| Component | Terms |
|---|---|
| `font/Omarchy Font.ttf` | MIT, Copyright 2026 Mark Cuda ([licence](font/LICENSE.Omarchy-Font)) |
| `logo.txt`, `logo-narrow.txt` | Omarchy's own wordmark art, under Omarchy's MIT licence |
| `starship.toml`, `tmux.conf` | Configuration for Starship and tmux, separate projects |

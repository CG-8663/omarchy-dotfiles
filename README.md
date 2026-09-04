# omarchy-dotfiles

A login banner and CLI layout for [Omarchy](https://omarchy.org): the Omarchy
wordmark in its own pink-to-blue gradient, a strapline, and a compact identity
card telling you which machine you just landed on.

```
  ___   __  __     _     ____    ____  _   _ __   __
 / _ \ |  \/  |   / \   |  _ \  / ___|| | | |\ \ / /
| | | || |\/| |  / _ \  | |_) || |    | |_| | \ V /
| |_| || |  | | / ___ \ |  _ < | |___ |  _  |  | |
 \___/ |_|  |_|/_/   \_\|_| \_\ \____||_| |_|  |_|

   Welcome to A Changing World with Omarchy
   Welcome to the Beautiful, Fun & Agentic Linux   @DHH

   login      you@workstation
   location   Studio, London
   system     Arch Linux (x86_64)
   omarchy    v3.1.2
   ipv4       10.0.0.40 (wlan0)
   ipv6       disabled
   tailscale  100.x.y.z
   uptime     3 hours, 12 minutes
```

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

Existing files are backed up to `*.chrbak` once, and every shell hook is written
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
export CHRONARA_WELCOME=0
```

## Testing it without touching your setup

See the banner and nothing else:

```sh
./install.sh --preview
```

Do a complete install against a throwaway `$HOME`, so your real dotfiles are
never touched:

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
  `tmux.conf`) were replaced, so uninstall puts the `.chrbak` backup back if
  there is one.

If a config has no backup, it is removed **only when it is byte-identical to the
copy this repo ships**. That is the only proof it came from here. A
`--welcome-only` install never writes `starship.toml`, and a file you wrote or
edited yourself will not match, so in both cases it is left alone with a warning
rather than deleted.

Every rc file is checked, not just the one for your current `$SHELL`, in case
you have switched shells since installing.

## Colours

The wordmark is coloured column by column to reproduce the gradient from
`omarchy-show-logo` rather than approximate it with a flat colour:

| Stop | Hex |
|---|---|
| pink | `#FF5FBF` |
| violet | `#C77DF5` |
| blue | `#7FB8FF` |

Truecolor terminals get 24-bit output. Terminals that do not advertise
`COLORTERM=truecolor` fall back to the nearest colours in the 256-colour cube.
Piping the banner to a file or a pipe drops colour entirely, so it stays
readable in logs.

## The identity card

| Field | Source |
|---|---|
| `login` | `id -un` and short hostname |
| `location` | `/etc/chronara-location`, else `~/.config/chronara/location` |
| `system` | `/etc/os-release`, or `sw_vers` on macOS |
| `omarchy` | `omarchy-version`, else `git describe` on `~/.local/share/omarchy` |
| `ipv4` | route to `1.1.1.1`, with the interface it egresses on |
| `ipv6` | first global address, skipping link-local and Tailscale's `fd7a::/16` |
| `tailscale` | `tailscale ip -4`, omitted when not installed |
| `uptime` | `uptime -p` where available |

Set the location label once per machine:

```sh
echo "Studio, London" | sudo tee /etc/chronara-location
```

Nothing here phones home, and nothing is written outside `~/.config`, the shell
rc files, and (with `--system`) `/etc/profile.d`, `/etc/zsh` and `/etc/tmux.conf`.

## Not on Omarchy?

It installs fine. The `omarchy` line reads `not detected` and everything else
works, so the same dotfiles cover an Omarchy desktop, an Arch server and a Mac.

## Credits

- **Omarchy** by [David Heinemeier Hansson](https://dhh.dk) (@dhh) and Basecamp,
  [omarchy.org](https://omarchy.org) / [basecamp/omarchy](https://github.com/basecamp/omarchy).
  The wordmark and its gradient are Omarchy's; this repo just renders them in the
  shell. The strapline is a nod to Omarchy's own framing of a beautiful, fun
  Linux, with "agentic" added because that is what these boxes are for.
- **Starship** ([starship.rs](https://starship.rs)) for the prompt this config drives.
- **tmux** for everything the `tmux.conf` sits on top of.

## Licence

MIT. See [LICENSE](LICENSE).

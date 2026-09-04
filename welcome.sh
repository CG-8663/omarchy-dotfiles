#!/usr/bin/env sh
# omarchy-dotfiles login banner.
# Same identity card as the standard Omarchy welcome (host, location, OS, IPv4,
# IPv6, Tailscale, uptime) with the Omarchy wordmark and strapline on top, plus
# an Omarchy version line when the box is actually running Omarchy.
# Runs on each interactive login shell. Installed by install-omarchy.sh into
# ~/.config/omarchy-dotfiles/welcome.sh, or /usr/local/share/omarchy-dotfiles/ for --system.
# POSIX sh, cross-platform: zsh/bash, Arch/Omarchy primarily, macOS tolerated.

# interactive shells only
case "$-" in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

# Opt out entirely for a given shell or box:  export OMARCHY_WELCOME=0
[ "${OMARCHY_WELCOME:-1}" = "0" ] && { return 0 2>/dev/null || exit 0; }

# Fire once per shell process. A login shell reads both the login rc and the
# interactive rc and both source this file, so without this guard you would see
# the banner twice in one window. The flag is deliberately NOT exported: a new
# terminal window, tab or tmux pane is a fresh process and shows it again, which
# is what "on login or terminal opening" means.
[ -n "${_OMA_WELCOME_SHOWN:-}" ] && { return 0 2>/dev/null || exit 0; }
_OMA_WELCOME_SHOWN=1

_oma_user=$(id -un 2>/dev/null || whoami 2>/dev/null)
_oma_host=$(hostname 2>/dev/null | cut -d. -f1)

# ---- system -----------------------------------------------------------------
if command -v sw_vers >/dev/null 2>&1; then
  _oma_sys="$(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) ($(uname -m))"
elif [ -r /etc/os-release ]; then
  _oma_sys="$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-Linux}") ($(uname -m))"
else
  _oma_sys="$(uname -s) ($(uname -m))"
fi

# ---- omarchy version --------------------------------------------------------
# Omarchy ships a version helper and keeps its checkout in ~/.local/share/omarchy.
# Fall back to the git describe of that checkout, then to a plain "not detected".
_oma_omarchy=""
if command -v omarchy-version >/dev/null 2>&1; then
  _oma_omarchy=$(omarchy-version 2>/dev/null | head -1)
fi
if [ -z "$_oma_omarchy" ] && [ -d "$HOME/.local/share/omarchy/.git" ]; then
  _oma_omarchy=$(git -C "$HOME/.local/share/omarchy" describe --tags --always 2>/dev/null)
fi
[ -z "$_oma_omarchy" ] && [ -d "$HOME/.local/share/omarchy" ] && _oma_omarchy="installed (version unknown)"
[ -z "$_oma_omarchy" ] && _oma_omarchy="not detected"

# ---- location: per-system label (file or hostname) --------------------------
if [ -r /etc/omarchy-location ]; then
  _oma_loc=$(head -1 /etc/omarchy-location 2>/dev/null)
elif [ -r "$HOME/.config/omarchy-dotfiles/location" ]; then
  _oma_loc=$(head -1 "$HOME/.config/omarchy-dotfiles/location" 2>/dev/null)
else
  _oma_loc="unset (set /etc/omarchy-location)"
fi

# ---- primary interface + IPv4 -----------------------------------------------
_oma_if=""; _oma_ip4=""
if command -v ip >/dev/null 2>&1; then                       # Linux
  _oma_ip4=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}')
  _oma_if=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1);exit}}')
  [ -z "$_oma_ip4" ] && _oma_ip4=$(hostname -I 2>/dev/null | awk '{print $1}')
elif command -v ipconfig >/dev/null 2>&1; then               # macOS
  _oma_if=$(route -n get default 2>/dev/null | awk '/interface:/{print $2;exit}')
  [ -n "$_oma_if" ] && _oma_ip4=$(ipconfig getifaddr "$_oma_if" 2>/dev/null)
  [ -z "$_oma_ip4" ] && { _oma_ip4=$(ipconfig getifaddr en0 2>/dev/null); _oma_if=${_oma_if:-en0}; }
fi
[ -z "$_oma_ip4" ] && _oma_ip4="none"

# ---- IPv6 (global LAN address; skip link-local and the Tailscale fd7a range) -
_oma_ip6=""
if command -v ip >/dev/null 2>&1; then
  [ -n "$_oma_if" ] && _oma_ip6=$(ip -6 addr show dev "$_oma_if" scope global 2>/dev/null | awk '$1=="inet6" && $2 !~ /^fd7a:115c/ {print $2;exit}')
  [ -z "$_oma_ip6" ] && _oma_ip6=$(ip -6 addr show scope global 2>/dev/null | awk '$1=="inet6" && $2 !~ /^fd7a:115c/ {print $2;exit}')
elif command -v ifconfig >/dev/null 2>&1; then
  _oma_ip6=$(ifconfig "${_oma_if:-en0}" 2>/dev/null | awk '/inet6 / && $2 !~ /^fe80/ && $2 !~ /^fd7a:115c/ {print $2;exit}')
fi
[ -z "$_oma_ip6" ] && _oma_ip6="disabled"

# ---- Tailscale IP -----------------------------------------------------------
_oma_ts=""
if command -v tailscale >/dev/null 2>&1; then
  _oma_ts=$(tailscale ip -4 2>/dev/null | head -1)
elif [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]; then
  _oma_ts=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4 2>/dev/null | head -1)
fi

# ---- uptime -----------------------------------------------------------------
if uptime -p >/dev/null 2>&1; then
  _oma_up=$(uptime -p 2>/dev/null | sed 's/^up //')
else
  _oma_up=$(uptime 2>/dev/null | sed 's/.*up //; s/,[[:space:]]*[0-9]* user.*//')
fi

# ---- colours ----------------------------------------------------------------
# Palette taken from the official `omarchy-show-logo` wordmark: a horizontal
# pink -> violet -> blue gradient on near-black.
#   pink   #FF5FBF     violet #C77DF5     blue   #7FB8FF
# PK/VI/BL are the three stops, used for text that is not part of the gradient.
if [ -t 1 ]; then
  if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
    _oma_tc=1
    PK=$(printf '\033[38;2;255;95;191m'); VI=$(printf '\033[38;2;199;125;245m')
    BL=$(printf '\033[38;2;127;184;255m')
  else
    _oma_tc=0
    PK=$(printf '\033[38;5;205m'); VI=$(printf '\033[38;5;141m')
    BL=$(printf '\033[38;5;111m')
  fi
  D=$(printf '\033[38;5;245m'); G=$(printf '\033[38;5;84m')
  B=$(printf '\033[1m'); R=$(printf '\033[0m')
else
  _oma_tc=0; PK=; VI=; BL=; D=; G=; B=; R=
fi

# ---- pick the wordmark ------------------------------------------------------
# Prefer the real Omarchy art over anything we could approximate. In order:
#   1. $OMARCHY_LOGO, if you point it at your own file
#   2. the box's own ~/.local/share/omarchy/logo.txt, so the banner always
#      matches the Omarchy version actually installed
#   3. our bundled copy of that same art (81 columns)
#   4. a narrower rendition of it for small terminals (64 columns)
#   5. a plain figlet wordmark, only if none of the above fit
_oma_cols=${COLUMNS:-0}
case "$_oma_cols" in ''|*[!0-9]*) _oma_cols=0 ;; esac
[ "$_oma_cols" -lt 1 ] && _oma_cols=$(tput cols 2>/dev/null || echo 80)

_oma_share=""
for _d in "$HOME/.config/omarchy-dotfiles" /usr/local/share/omarchy-dotfiles; do
  [ -f "$_d/logo.txt" ] && { _oma_share="$_d"; break; }
done

# Width in COLUMNS, not bytes. Each block or braille glyph is three bytes in
# UTF-8, so a byte count over-reports by ~3x and rejects art that fits fine.
# gawk under a UTF-8 locale counts characters; BSD awk (macOS) counts bytes.
# Detect which we have by measuring a glyph, then step three bytes at a time
# when it is the byte-counting kind. The same walk is what keeps substr() from
# slicing a glyph into thirds further down.
_oma_artwidth() {
  awk '
    BEGIN { gw = length("█") }
    {
      n = length($0); i = 1; col = 0
      while (i <= n) {
        if (substr($0, i, 1) == " ") i += 1; else i += gw
        col++
      }
      if (col > m) m = col
    }
    END { print m+0 }' "$1" 2>/dev/null
}

_oma_fits() {
  [ -f "$1" ] || return 1
  _w=$(_oma_artwidth "$1")
  [ -n "$_w" ] && [ "$_w" -gt 0 ] && [ "$_w" -le "$_oma_cols" ]
}

_oma_logo=""
for _cand in \
  "${OMARCHY_LOGO:-}" \
  "$HOME/.local/share/omarchy/logo.txt" \
  "${_oma_share:+$_oma_share/logo.txt}" \
  "${_oma_share:+$_oma_share/logo-narrow.txt}"
do
  [ -n "$_cand" ] || continue
  if _oma_fits "$_cand"; then _oma_logo="$_cand"; break; fi
done
unset _d _cand _w

# ---- colour the wordmark ----------------------------------------------------
# Column by column, so it reproduces the gradient rather than approximating it
# with one flat colour. Buffers the art first to learn its true width, so the
# gradient spans the wordmark itself rather than a guessed number of columns.
# Falls back to the 256-colour cube without truecolor, and to plain text when
# stdout is not a terminal.
_oma_wordmark() {
  if [ -z "$R" ] || ! command -v awk >/dev/null 2>&1; then cat; return; fi
  awk -v tc="$_oma_tc" '
    function lerp(a, b, t) { return int(a + (b-a)*t + 0.5) }
    function q(v)          { return int(v*5/255 + 0.5) }
    BEGIN { gw = length("█") }   # 1 on a character-aware awk, 3 on a byte one
    {
      line[NR] = $0
      n = length($0); i = 1; col = 0
      while (i <= n) { if (substr($0, i, 1) == " ") i += 1; else i += gw; col++ }
      if (col > w) w = col
    }
    END {
      for (ln = 1; ln <= NR; ln++) {
        s = line[ln]; n = length(s); i = 1; col = 0; out = ""
        while (i <= n) {
          c = substr(s, i, 1)
          if (c == " ") { out = out c; i += 1; col++; continue }
          g = substr(s, i, gw); i += gw
          t = (w > 1) ? col/(w-1) : 0
          if (t > 1) t = 1
          if (t < 0.5) { u = t/0.5;       r=lerp(255,199,u); gg=lerp( 95,125,u); b=lerp(191,245,u) }
          else         { u = (t-0.5)/0.5; r=lerp(199,127,u); gg=lerp(125,184,u); b=lerp(245,255,u) }
          if (tc == "1") out = out sprintf("\033[38;2;%d;%d;%dm%s", r, gg, b, g)
          else           out = out sprintf("\033[38;5;%dm%s", 16 + 36*q(r) + 6*q(gg) + q(b), g)
          col++
        }
        print out "\033[0m"
      }
    }'
}

# ---- render -----------------------------------------------------------------
printf '\n'
if [ -n "$_oma_logo" ]; then
  _oma_wordmark < "$_oma_logo"
else
  _oma_wordmark <<'ART'
  ___   __  __     _     ____    ____  _   _ __   __
 / _ \ |  \/  |   / \   |  _ \  / ___|| | | |\ \ / /
| | | || |\/| |  / _ \  | |_) || |    | |_| | \ V / 
| |_| || |  | | / ___ \ |  _ < | |___ |  _  |  | |  
 \___/ |_|  |_|/_/   \_\|_| \_\ \____||_| |_|  |_|  
ART
fi
printf '\n   %s%sWelcome to A Changing World with Omarchy%s\n' "$B" "$PK" "$R"
printf '   %sand to the Beautiful, Fun & Agentic Linux%s   %s@DHH%s\n\n' "$VI" "$R" "$BL" "$R"

printf '   %slogin%s      %s%s@%s%s\n'  "$D" "$R" "$G" "$_oma_user" "$_oma_host" "$R"
printf '   %slocation%s   %s\n'         "$D" "$R" "$_oma_loc"
printf '   %ssystem%s     %s\n'         "$D" "$R" "$_oma_sys"
printf '   %somarchy%s    %s%s%s\n'     "$D" "$R" "$PK" "$_oma_omarchy" "$R"
printf '   %sipv4%s       %s%s%s%s\n'   "$D" "$R" "$BL" "$_oma_ip4" "$R" "$([ -n "$_oma_if" ] && printf ' (%s)' "$_oma_if")"
printf '   %sipv6%s       %s\n'         "$D" "$R" "$_oma_ip6"
[ -n "$_oma_ts" ] && printf '   %stailscale%s  %s%s%s\n' "$D" "$R" "$VI" "$_oma_ts" "$R"
[ -n "$_oma_up" ] && printf '   %suptime%s     %s\n' "$D" "$R" "$_oma_up"
printf '\n   %s%sThe Future of AI Compute%s\n\n' "$B" "$BL" "$R"

unset PK VI BL D G B R _oma_tc _oma_cols _oma_share _oma_logo _oma_user _oma_host _oma_sys _oma_omarchy _oma_loc _oma_if _oma_ip4 _oma_ip6 _oma_ts _oma_up
unset -f _oma_wordmark _oma_fits 2>/dev/null || true

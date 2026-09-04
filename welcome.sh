#!/usr/bin/env sh
# Chronara x Omarchy login banner.
# Same identity card as the standard Chronara welcome (host, location, OS, IPv4,
# IPv6, Tailscale, uptime) with the Omarchy wordmark and strapline on top, plus
# an Omarchy version line when the box is actually running Omarchy.
# Runs on each interactive login shell. Installed by install-omarchy.sh into
# ~/.config/chronara/welcome.sh, or /usr/local/share/chronara/ for --system.
# POSIX sh, cross-platform: zsh/bash, Arch/Omarchy primarily, macOS tolerated.

# interactive shells only
case "$-" in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

# Opt out entirely for a given shell or box:  export CHRONARA_WELCOME=0
[ "${CHRONARA_WELCOME:-1}" = "0" ] && { return 0 2>/dev/null || exit 0; }

# Fire once per shell process. A login shell reads both the login rc and the
# interactive rc and both source this file, so without this guard you would see
# the banner twice in one window. The flag is deliberately NOT exported: a new
# terminal window, tab or tmux pane is a fresh process and shows it again, which
# is what "on login or terminal opening" means.
[ -n "${_CHR_WELCOME_SHOWN:-}" ] && { return 0 2>/dev/null || exit 0; }
_CHR_WELCOME_SHOWN=1

_chr_user=$(id -un 2>/dev/null || whoami 2>/dev/null)
_chr_host=$(hostname 2>/dev/null | cut -d. -f1)

# ---- system -----------------------------------------------------------------
if command -v sw_vers >/dev/null 2>&1; then
  _chr_sys="$(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) ($(uname -m))"
elif [ -r /etc/os-release ]; then
  _chr_sys="$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-Linux}") ($(uname -m))"
else
  _chr_sys="$(uname -s) ($(uname -m))"
fi

# ---- omarchy version --------------------------------------------------------
# Omarchy ships a version helper and keeps its checkout in ~/.local/share/omarchy.
# Fall back to the git describe of that checkout, then to a plain "not detected".
_chr_omarchy=""
if command -v omarchy-version >/dev/null 2>&1; then
  _chr_omarchy=$(omarchy-version 2>/dev/null | head -1)
fi
if [ -z "$_chr_omarchy" ] && [ -d "$HOME/.local/share/omarchy/.git" ]; then
  _chr_omarchy=$(git -C "$HOME/.local/share/omarchy" describe --tags --always 2>/dev/null)
fi
[ -z "$_chr_omarchy" ] && [ -d "$HOME/.local/share/omarchy" ] && _chr_omarchy="installed (version unknown)"
[ -z "$_chr_omarchy" ] && _chr_omarchy="not detected"

# ---- location: per-system label (file or hostname) --------------------------
if [ -r /etc/chronara-location ]; then
  _chr_loc=$(head -1 /etc/chronara-location 2>/dev/null)
elif [ -r "$HOME/.config/chronara/location" ]; then
  _chr_loc=$(head -1 "$HOME/.config/chronara/location" 2>/dev/null)
else
  _chr_loc="unset (set /etc/chronara-location)"
fi

# ---- primary interface + IPv4 -----------------------------------------------
_chr_if=""; _chr_ip4=""
if command -v ip >/dev/null 2>&1; then                       # Linux
  _chr_ip4=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}')
  _chr_if=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1);exit}}')
  [ -z "$_chr_ip4" ] && _chr_ip4=$(hostname -I 2>/dev/null | awk '{print $1}')
elif command -v ipconfig >/dev/null 2>&1; then               # macOS
  _chr_if=$(route -n get default 2>/dev/null | awk '/interface:/{print $2;exit}')
  [ -n "$_chr_if" ] && _chr_ip4=$(ipconfig getifaddr "$_chr_if" 2>/dev/null)
  [ -z "$_chr_ip4" ] && { _chr_ip4=$(ipconfig getifaddr en0 2>/dev/null); _chr_if=${_chr_if:-en0}; }
fi
[ -z "$_chr_ip4" ] && _chr_ip4="none"

# ---- IPv6 (global LAN address; skip link-local and the Tailscale fd7a range) -
_chr_ip6=""
if command -v ip >/dev/null 2>&1; then
  [ -n "$_chr_if" ] && _chr_ip6=$(ip -6 addr show dev "$_chr_if" scope global 2>/dev/null | awk '$1=="inet6" && $2 !~ /^fd7a:115c/ {print $2;exit}')
  [ -z "$_chr_ip6" ] && _chr_ip6=$(ip -6 addr show scope global 2>/dev/null | awk '$1=="inet6" && $2 !~ /^fd7a:115c/ {print $2;exit}')
elif command -v ifconfig >/dev/null 2>&1; then
  _chr_ip6=$(ifconfig "${_chr_if:-en0}" 2>/dev/null | awk '/inet6 / && $2 !~ /^fe80/ && $2 !~ /^fd7a:115c/ {print $2;exit}')
fi
[ -z "$_chr_ip6" ] && _chr_ip6="disabled"

# ---- Tailscale IP -----------------------------------------------------------
_chr_ts=""
if command -v tailscale >/dev/null 2>&1; then
  _chr_ts=$(tailscale ip -4 2>/dev/null | head -1)
elif [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]; then
  _chr_ts=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4 2>/dev/null | head -1)
fi

# ---- uptime -----------------------------------------------------------------
if uptime -p >/dev/null 2>&1; then
  _chr_up=$(uptime -p 2>/dev/null | sed 's/^up //')
else
  _chr_up=$(uptime 2>/dev/null | sed 's/.*up //; s/,[[:space:]]*[0-9]* user.*//')
fi

# ---- colours ----------------------------------------------------------------
# Palette taken from the official `omarchy-show-logo` wordmark: a horizontal
# pink -> violet -> blue gradient on near-black.
#   pink   #FF5FBF     violet #C77DF5     blue   #7FB8FF
# PK/VI/BL are the three stops, used for text that is not part of the gradient.
if [ -t 1 ]; then
  if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
    _chr_tc=1
    PK=$(printf '\033[38;2;255;95;191m'); VI=$(printf '\033[38;2;199;125;245m')
    BL=$(printf '\033[38;2;127;184;255m')
  else
    _chr_tc=0
    PK=$(printf '\033[38;5;205m'); VI=$(printf '\033[38;5;141m')
    BL=$(printf '\033[38;5;111m')
  fi
  D=$(printf '\033[38;5;245m'); G=$(printf '\033[38;5;84m')
  B=$(printf '\033[1m'); R=$(printf '\033[0m')
else
  _chr_tc=0; PK=; VI=; BL=; D=; G=; B=; R=
fi

# Colour the wordmark column by column so it reproduces the real gradient rather
# than a flat approximation of it. Falls back to the 256-colour cube when the
# terminal does not advertise truecolor, and to plain text when not a tty.
_chr_wordmark() {
  if [ -z "$R" ] || ! command -v awk >/dev/null 2>&1; then cat; return; fi
  awk -v tc="$_chr_tc" -v w=51 '
    function lerp(a,b,t) { return int(a + (b-a)*t + 0.5) }
    function q(v) { return int(v*5/255 + 0.5) }
    {
      n = length($0); out = ""
      for (i = 1; i <= n; i++) {
        c = substr($0, i, 1)
        if (c == " ") { out = out c; continue }
        t = (w > 1) ? (i-1)/(w-1) : 0
        if (t > 1) t = 1
        if (t < 0.5) { u = t/0.5;       r=lerp(255,199,u); g=lerp( 95,125,u); b=lerp(191,245,u) }
        else         { u = (t-0.5)/0.5; r=lerp(199,127,u); g=lerp(125,184,u); b=lerp(245,255,u) }
        if (tc == "1") out = out sprintf("\033[38;2;%d;%d;%dm%s", r, g, b, c)
        else           out = out sprintf("\033[38;5;%dm%s", 16 + 36*q(r) + 6*q(g) + q(b), c)
      }
      print out "\033[0m"
    }'
}

# ---- render -----------------------------------------------------------------
printf '\n'
_chr_wordmark <<'ART'
  ___   __  __     _     ____    ____  _   _ __   __
 / _ \ |  \/  |   / \   |  _ \  / ___|| | | |\ \ / /
| | | || |\/| |  / _ \  | |_) || |    | |_| | \ V / 
| |_| || |  | | / ___ \ |  _ < | |___ |  _  |  | |  
 \___/ |_|  |_|/_/   \_\|_| \_\ \____||_| |_|  |_|  
ART
printf '\n   %s%sWelcome to A Changing World with Omarchy%s\n' "$B" "$PK" "$R"
printf '   %sWelcome to the Beautiful, Fun & Agentic Linux%s   %s@DHH%s\n\n' "$VI" "$R" "$BL" "$R"

printf '   %slogin%s      %s%s@%s%s\n'  "$D" "$R" "$G" "$_chr_user" "$_chr_host" "$R"
printf '   %slocation%s   %s\n'         "$D" "$R" "$_chr_loc"
printf '   %ssystem%s     %s\n'         "$D" "$R" "$_chr_sys"
printf '   %somarchy%s    %s%s%s\n'     "$D" "$R" "$PK" "$_chr_omarchy" "$R"
printf '   %sipv4%s       %s%s%s%s\n'   "$D" "$R" "$BL" "$_chr_ip4" "$R" "$([ -n "$_chr_if" ] && printf ' (%s)' "$_chr_if")"
printf '   %sipv6%s       %s\n'         "$D" "$R" "$_chr_ip6"
[ -n "$_chr_ts" ] && printf '   %stailscale%s  %s%s%s\n' "$D" "$R" "$VI" "$_chr_ts" "$R"
[ -n "$_chr_up" ] && printf '   %suptime%s     %s\n' "$D" "$R" "$_chr_up"
printf '\n   %s%sChronara AI%s %sthe future of compute%s\n\n' "$B" "$BL" "$R" "$D" "$R"

unset PK VI BL D G B R _chr_tc _chr_user _chr_host _chr_sys _chr_omarchy _chr_loc _chr_if _chr_ip4 _chr_ip6 _chr_ts _chr_up
unset -f _chr_wordmark 2>/dev/null || true

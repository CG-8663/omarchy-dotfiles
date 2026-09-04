#!/usr/bin/env bash
# omarchy-dotfiles: a Chronara-flavoured login banner and CLI layout for Omarchy.
#
# Same Chronara CLI layout as the base install (Starship bordered prompt, tmux,
# per-login identity card) but with the Omarchy wordmark and strapline as the
# login banner. Intended for Omarchy boxes; runs anywhere the base install runs.
#
# Safe to re-run: existing files are backed up to *.chrbak once, shell hooks are
# written between guard markers so they are never duplicated.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMA_DIR="$REPO_DIR"
OS="$(uname -s)"
MARK_BEGIN="# >>> chronara-dotfiles >>>"
MARK_END="# <<< chronara-dotfiles <<<"
DRY_RUN=0

say()  { printf '\033[1;38;5;205m[oma]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[oma]\033[0m %s\n' "$1"; }

backup() {  # backup a path once if it exists and is not already backed up
  local f="$1"
  if [ -e "$f" ] && [ ! -e "$f.chrbak" ]; then
    cp -a "$f" "$f.chrbak"
    say "backed up $f -> $f.chrbak"
  fi
}

# ---- 0. is this actually Omarchy? -------------------------------------------
# Not fatal. The banner degrades to "omarchy  not detected" and everything else
# still works, so a non-Omarchy box gets a warning rather than a refusal.
detect_omarchy() {
  if command -v omarchy-version >/dev/null 2>&1; then
    say "Omarchy detected: $(omarchy-version 2>/dev/null | head -1)"
  elif [ -d "$HOME/.local/share/omarchy" ]; then
    say "Omarchy checkout found at ~/.local/share/omarchy"
  else
    warn "no Omarchy install found; banner will show 'not detected', rest still installs"
  fi
}

# ---- 1. install starship ----------------------------------------------------
install_starship() {
  if command -v starship >/dev/null 2>&1; then
    say "starship already installed ($(starship --version | head -1))"
    return
  fi
  if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
    say "installing starship via Homebrew"
    brew install starship
  elif command -v pacman >/dev/null 2>&1; then
    say "installing starship via pacman (Omarchy/Arch)"
    sudo pacman -S --needed --noconfirm starship
  else
    say "installing starship via official script (-> ~/.local/bin, no sudo)"
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
  fi
}

# ---- 2. a Nerd Font for the glyphs ------------------------------------------
install_font() {
  if [ "$OS" = "Darwin" ]; then
    command -v brew >/dev/null 2>&1 || { warn "no brew: install FiraCode Nerd Font manually"; return; }
    if brew list --cask font-fira-code-nerd-font >/dev/null 2>&1; then
      say "Nerd Font already installed"
    else
      say "installing FiraCode Nerd Font"
      brew install --cask font-fira-code-nerd-font || warn "font install failed, continuing"
    fi
  elif command -v pacman >/dev/null 2>&1; then
    # Omarchy already ships a Nerd Font, so this is usually a no-op.
    if pacman -Qq ttf-firacode-nerd >/dev/null 2>&1; then
      say "Nerd Font already installed"
    else
      say "installing ttf-firacode-nerd"
      sudo pacman -S --needed --noconfirm ttf-firacode-nerd || warn "font install failed, continuing"
    fi
  else
    warn "install a Nerd Font yourself if glyphs look wrong (e.g. FiraCode Nerd Font)"
  fi
}

# ---- 3a. the Omarchy welcome banner (always) --------------------------------
install_welcome_file() {
  mkdir -p "$HOME/.config/chronara"
  backup "$HOME/.config/chronara/welcome.sh"
  cp "$REPO_DIR/welcome.sh" "$HOME/.config/chronara/welcome.sh"
  chmod +x "$HOME/.config/chronara/welcome.sh"
  say "installed ~/.config/chronara/welcome.sh (Omarchy banner)"
  # The wordmark art itself. On a real Omarchy box the banner prefers that
  # box's own ~/.local/share/omarchy/logo.txt so it tracks the installed
  # version; these are the fallback, plus a narrow rendition for small
  # terminals.
  local art
  for art in logo.txt logo-narrow.txt; do
    backup "$HOME/.config/chronara/$art"
    cp "$REPO_DIR/$art" "$HOME/.config/chronara/$art"
  done
  say "installed wordmark art (logo.txt 81 cols, logo-narrow.txt 64 cols)"
}

# ---- 3b. prompt + tmux config (full install only) ---------------------------
# These come from the repo root: the Chronara CLI layout is shared, only the
# banner differs between the two editions.
install_configs() {
  mkdir -p "$HOME/.config"
  backup "$HOME/.config/starship.toml"
  cp "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"
  say "installed ~/.config/starship.toml (Chronara bordered prompt)"

  backup "$HOME/.tmux.conf"
  cp "$REPO_DIR/tmux.conf" "$HOME/.tmux.conf"
  say "installed ~/.tmux.conf"
}

# ---- helper: write a guarded block into a file (idempotent) ------------------
write_block() {  # $1=file  $2=block body (may be multi-line)
  local rc="$1" body="$2" tmp
  touch "$rc"; backup "$rc"
  if grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null; then
    tmp="$(mktemp)"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b{skip=1} !skip{print} $0==e{skip=0}' "$rc" > "$tmp"
    mv "$tmp" "$rc"
  fi
  {
    printf '\n%s\n' "$MARK_BEGIN"
    printf '%s\n' "$body"
    printf '%s\n' "$MARK_END"
  } >> "$rc"
}

# ---- 4. wire prompt + banner into the shell rc files ------------------------
# The banner must fire on login AND on opening a new terminal. Those are two
# different files: a login shell reads the login rc (.zprofile/.bash_profile),
# a new terminal tab is usually a non-login interactive shell and reads only the
# interactive rc (.zshrc/.bashrc). Hooking just the login rc, which is what the
# base install does, means a new tab shows nothing.
#
# So both files get the banner, and welcome-omarchy.sh carries a once-per-shell
# guard so a login shell that reads both does not print it twice.
#
# One guarded block per file: the marker pair is shared, so the prompt and the
# banner have to go into the interactive rc together or the second write_block
# would overwrite the first.
hook_shell() {  # $1 = 1 to include the prompt, 0 for banner only
  local want_prompt="$1"
  local irc lrc init src body
  src='[ -f "$HOME/.config/chronara/welcome.sh" ] && . "$HOME/.config/chronara/welcome.sh"'

  case "$(basename "${SHELL:-}")" in
    zsh)  irc="$HOME/.zshrc";  lrc="$HOME/.zprofile";      init='eval "$(starship init zsh)"' ;;
    bash) irc="$HOME/.bashrc"; lrc="$HOME/.bash_profile";  init='eval "$(starship init bash)"' ;;
    *)    irc="$HOME/.profile"; lrc=""; init='command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"' ;;
  esac

  # interactive rc: PATH + prompt + banner (new terminal window or tab)
  if [ "$want_prompt" = "1" ]; then
    body="$(printf 'export PATH="$HOME/.local/bin:$PATH"\n%s\n%s' "$init" "$src")"
  else
    body="$src"
  fi
  write_block "$irc" "$body"
  say "hooked prompt + banner into $irc (new terminal)"

  # login rc: banner on login. bash login shells do not read .bashrc at all, so
  # they also need the interactive rc pulled in or they get no prompt over SSH.
  if [ -n "$lrc" ] && [ "$lrc" != "$irc" ]; then
    if [ "$(basename "${SHELL:-}")" = "bash" ]; then
      body="$(printf '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"\n%s' "$src")"
    else
      body="$src"
    fi
    write_block "$lrc" "$body"
    say "hooked banner into $lrc (login)"
  fi
}

# ---- optional: system-wide banner for shared boxes (root, --system) ---------
install_system_welcome() {
  [ "$(id -u)" = "0" ] || { warn "--system needs root; skipping system-wide welcome"; return; }
  mkdir -p /usr/local/share/chronara
  backup /usr/local/share/chronara/welcome.sh
  cp "$REPO_DIR/welcome.sh" /usr/local/share/chronara/welcome.sh
  chmod +x /usr/local/share/chronara/welcome.sh
  local art
  for art in logo.txt logo-narrow.txt; do
    backup "/usr/local/share/chronara/$art"
    cp "$REPO_DIR/$art" "/usr/local/share/chronara/$art"
  done
  # Same login-vs-new-terminal split as the per-user hooks, at system level.
  # /etc/profile.d covers login shells only; an interactive non-login shell
  # (a new terminal tab) reads /etc/bash.bashrc or /etc/zsh/zshrc instead.
  local src='[ -f /usr/local/share/chronara/welcome.sh ] && . /usr/local/share/chronara/welcome.sh'
  if [ -d /etc/profile.d ]; then
    printf '# Chronara x Omarchy login banner (all users). Managed by chronara-dotfiles.\n%s\n' "$src" \
      > /etc/profile.d/chronara-welcome.sh
    say "installed /etc/profile.d/chronara-welcome.sh (login, all users)"
  fi
  if [ -f /etc/bash.bashrc ]; then   # Arch/Debian: interactive non-login bash
    write_block /etc/bash.bashrc "$src"
    say "installed /etc/bash.bashrc hook (new terminal, bash)"
  fi
  if [ -d /etc/zsh ]; then           # zsh reads neither /etc/profile.d nor bash.bashrc
    write_block /etc/zsh/zprofile "$src"
    say "installed /etc/zsh/zprofile hook (login, zsh)"
    write_block /etc/zsh/zshrc "$src"
    say "installed /etc/zsh/zshrc hook (new terminal, zsh)"
  fi
}

# ---- optional: system-wide prompt for shared boxes (root, --system) ---------
install_system_prompt() {
  [ "$(id -u)" = "0" ] || { warn "--system needs root; skipping system-wide prompt"; return; }
  if [ ! -x /usr/local/bin/starship ] && ! command -v starship >/dev/null 2>&1; then
    say "installing starship system-wide (-> /usr/local/bin)"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin
  else
    say "starship already present"
  fi
  mkdir -p /usr/local/share/chronara
  cp "$REPO_DIR/starship.toml" /usr/local/share/chronara/starship.toml
  cp "$REPO_DIR/tmux.conf" /etc/tmux.conf && say "installed /etc/tmux.conf (all users)"
  cat > /etc/profile.d/chronara-prompt.sh <<'PROMPT'
# Chronara bordered prompt (all users). Managed by chronara-dotfiles.
case "$-" in *i*)
  [ -z "${STARSHIP_CONFIG:-}" ] && export STARSHIP_CONFIG=/usr/local/share/chronara/starship.toml
  if command -v starship >/dev/null 2>&1; then
    if   [ -n "${ZSH_VERSION:-}" ];  then eval "$(starship init zsh)"
    elif [ -n "${BASH_VERSION:-}" ]; then eval "$(starship init bash)"; fi
  fi
;; esac
PROMPT
  say "installed /etc/profile.d/chronara-prompt.sh (all users)"
  # /etc/zsh/zshrc carries BOTH the prompt and the banner. install_system_welcome
  # already wrote a guarded block here and the marker pair is shared, so writing
  # the prompt on its own would silently drop the banner. Emit them together.
  if [ -d /etc/zsh ]; then
    write_block /etc/zsh/zshrc "$(cat <<'ZBLOCK'
[ -z "${STARSHIP_CONFIG:-}" ] && export STARSHIP_CONFIG=/usr/local/share/chronara/starship.toml
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
[ -f /usr/local/share/chronara/welcome.sh ] && . /usr/local/share/chronara/welcome.sh
ZBLOCK
)"
    say "installed /etc/zsh/zshrc hook (prompt + banner, zsh interactive)"
  fi
}

# ---- uninstall --------------------------------------------------------------
# Two different jobs, and conflating them loses your edits:
#   rc files  - we APPENDED a guarded block, so remove just that block and leave
#               everything you have added since alone.
#   configs   - we OVERWROTE the whole file, so put the .chrbak backup back if
#               there is one, otherwise take our copy away.
remove_block() {  # $1 = file
  local rc="$1" tmp
  [ -f "$rc" ] || return 0
  grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null || return 0
  if [ "$DRY_RUN" = "1" ]; then say "would remove guarded block from $rc"; return 0; fi
  tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b{skip=1} !skip{print} $0==e{skip=0}' "$rc" > "$tmp"
  # the installer writes a blank line before the block; do not let repeated
  # install/uninstall cycles pile those up at the end of the file
  awk 'BEGIN{n=0} {lines[NR]=$0} END{ last=NR; while(last>0 && lines[last]~/^[[:space:]]*$/) last--; for(i=1;i<=last;i++) print lines[i] }' "$tmp" > "$tmp.2"
  mv "$tmp.2" "$rc"; rm -f "$tmp"
  say "removed guarded block from $rc"
}

restore_file() {  # $1 = a file we may have overwritten  $2 = our shipped copy
  local f="$1" ours="$2"
  if [ -e "$f.chrbak" ]; then
    # a backup exists, so we definitely overwrote something: put it back
    if [ "$DRY_RUN" = "1" ]; then say "would restore $f from $f.chrbak"; return 0; fi
    mv "$f.chrbak" "$f"; say "restored $f from backup"
    return 0
  fi
  [ -e "$f" ] || return 0
  # No backup. Only delete it if it is byte-identical to what we ship, which is
  # the only proof we put it there. --welcome-only never installs starship.toml
  # or tmux.conf, so without this check an uninstall would delete a config the
  # user wrote themselves.
  if [ -n "$ours" ] && [ -e "$ours" ] && cmp -s "$f" "$ours"; then
    if [ "$DRY_RUN" = "1" ]; then say "would remove $f"; return 0; fi
    rm -f "$f"; say "removed $f"
  else
    warn "left $f alone: no backup and it does not match our copy (yours, or edited)"
  fi
}

uninstall_user() {
  # Every rc we might have touched, not just the one for the current $SHELL:
  # you may have switched shells since installing.
  local rc
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.profile"; do
    remove_block "$rc"
  done
  restore_file "$HOME/.config/chronara/welcome.sh"     "$REPO_DIR/welcome.sh"
  restore_file "$HOME/.config/chronara/logo.txt"        "$REPO_DIR/logo.txt"
  restore_file "$HOME/.config/chronara/logo-narrow.txt" "$REPO_DIR/logo-narrow.txt"
  restore_file "$HOME/.config/starship.toml"        "$REPO_DIR/starship.toml"
  restore_file "$HOME/.tmux.conf"                   "$REPO_DIR/tmux.conf"
  if [ "$DRY_RUN" != "1" ] && [ -d "$HOME/.config/chronara" ]; then
    rmdir "$HOME/.config/chronara" 2>/dev/null && say "removed empty ~/.config/chronara"
  fi
}

uninstall_system() {
  if [ "$(id -u)" != "0" ]; then warn "--system uninstall needs root; skipping system-wide files"; return; fi
  local f
  for f in /etc/profile.d/chronara-welcome.sh /etc/profile.d/chronara-prompt.sh; do
    if [ -e "$f" ]; then
      if [ "$DRY_RUN" = "1" ]; then say "would remove $f"; else rm -f "$f"; say "removed $f"; fi
    fi
  done
  for f in /etc/zsh/zprofile /etc/zsh/zshrc /etc/bash.bashrc; do
    remove_block "$f"
  done
  restore_file /etc/tmux.conf "$REPO_DIR/tmux.conf"
  restore_file /usr/local/share/chronara/welcome.sh     "$REPO_DIR/welcome.sh"
  restore_file /usr/local/share/chronara/logo.txt        "$REPO_DIR/logo.txt"
  restore_file /usr/local/share/chronara/logo-narrow.txt "$REPO_DIR/logo-narrow.txt"
  if [ -d /usr/local/share/chronara ]; then
    if [ "$DRY_RUN" = "1" ]; then say "would remove /usr/local/share/chronara"
    else rm -rf /usr/local/share/chronara; say "removed /usr/local/share/chronara"; fi
  fi
}

usage() {
  cat <<EOF
omarchy-dotfiles installer

  ./install.sh                  full install for the current user
                                    (Starship prompt + tmux + Omarchy banner)
  ./install.sh --system         FULL install for ALL users (root), via /etc/profile.d
  ./install.sh --welcome-only   banner only, no prompt changes
  ./install.sh --preview        print the banner and exit, change nothing

  ./install.sh --uninstall      remove the banner and hooks for the current user
  ./install.sh --uninstall --system
                                    also remove the system-wide files (root)
  ./install.sh --dry-run --uninstall
                                    show what an uninstall would touch, change nothing

Re-running an install OVERWRITES in place: the banner file is replaced and the
guarded rc block is rewritten, never appended twice. To switch between versions
just run the one you want; you do not need to uninstall first.

Uninstall removes only the guarded block from your rc files, so anything you
added yourself is kept. Files that were overwritten wholesale (starship.toml,
tmux.conf, the banner) are restored from their .chrbak backup when one exists.
EOF
}

preview() {
  # Force the interactive guard so the banner renders in a plain shell.
  sh -c 'set -i; . "$1"' _ "$REPO_DIR/welcome.sh" 2>/dev/null \
    || bash -i "$REPO_DIR/welcome.sh"
}

main() {
  local system=0 welcome_only=0 uninstall=0 a
  for a in "$@"; do
    case "$a" in
      --system)       system=1 ;;
      --welcome-only) welcome_only=1 ;;
      --uninstall)    uninstall=1 ;;
      --dry-run)      DRY_RUN=1 ;;
      --preview)      preview; return 0 ;;
      -h|--help)      usage; return 0 ;;
      *)              warn "unknown option: $a"; usage; return 2 ;;
    esac
  done

  if [ "$uninstall" = "1" ]; then
    [ "$DRY_RUN" = "1" ] && say "DRY RUN: nothing will be changed"
    say "uninstalling (system=$system)"
    uninstall_user
    [ "$system" = "1" ] && uninstall_system
    say "done. open a new login shell to confirm the banner is gone."
    return 0
  fi

  say "installing omarchy-dotfiles on $OS (welcome-only=$welcome_only system=$system)"
  detect_omarchy
  install_welcome_file
  if [ "$system" = "1" ]; then
    install_system_welcome
    if [ "$welcome_only" = "0" ]; then
      install_font
      install_system_prompt
    fi
  else
    if [ "$welcome_only" = "0" ]; then
      install_starship
      install_font
      install_configs
      hook_shell 1
    else
      hook_shell 0
    fi
  fi
  say "done. open a new login shell (or: exec \$SHELL -l) to see it."
}
main "$@"

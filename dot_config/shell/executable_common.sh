# ~/.config/shell/common.sh — portable base shell setup.
#
# Sourced by both ~/.bashrc and ~/.zshrc on every machine (Omarchy, macOS,
# Proxmox/Linux servers), BEFORE any platform-specific config, so Omarchy's
# rc and ~/.{bash,zsh}rc.local can override anything here.
#
# Keep this POSIX-ish: no bashisms, no zsh-isms — it runs under both.

# --- Homebrew (macOS Apple Silicon / Intel, and Linuxbrew) -------------------
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew

# --- PATH -------------------------------------------------------------------
# Prepend a directory only if it exists and isn't already on PATH.
_path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

_path_prepend "/usr/local/bin"
_path_prepend "$HOME/.opencode/bin"
_path_prepend "$HOME/rlos-workspace/bin"
# Android platform-tools: Linux SDK location, then the macOS default.
_path_prepend "/opt/android-sdk/platform-tools"
_path_prepend "$HOME/Library/Android/sdk/platform-tools"
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"
export PATH

# --- Listing: eza if available, else GNU coreutils (Linux) / BSD ls (macOS) --
# ll/la/l use `command ls` so they never recursively re-expand the `ls` alias.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto'
  alias la='eza -a --group-directories-first --icons=auto'
  alias l='eza --group-directories-first --icons=auto'
elif ls --color=auto >/dev/null 2>&1; then
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias ll='command ls -alF --color=auto'
  alias la='command ls -A --color=auto'
  alias l='command ls -CF --color=auto'
else
  export CLICOLOR=1
  alias ls='ls -G'
  alias ll='command ls -alFG'
  alias la='command ls -AG'
  alias l='command ls -CFG'
fi

# --- aliases ----------------------------------------------------------------
alias lanip="$HOME/.local/bin/lanip.sh"
alias wanip="$HOME/.local/bin/wanip.sh"
alias czd='chezmoi diff'
alias cza='chezmoi apply'
alias czu='chezmoi update'

# --- functions --------------------------------------------------------------
mkcd() { mkdir -p "$1" && cd "$1"; }

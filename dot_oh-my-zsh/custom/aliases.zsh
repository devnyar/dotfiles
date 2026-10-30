# environment paths are set in ~/.config/shell/common.sh (shared with bash)

alias reload="source ~/.zshrc"

alias edit-alias="chezmoi edit --apply ~/.oh-my-zsh/custom/aliases.zsh && source ~/.zshrc"

# android debug bridge
alias a="adb "
alias ad="adb devices"
alias ak="adb kill-server"
alias grep_prop="adb shell getprop | grep "

# rockchip
alias rd="rkut ld"
alias ru="rkut uf update.img"

# Claude code
alias cr="claude --resume "
alias cu="mise upgrade claude"

# general
alias tree="tree -h"
alias cze="chezmoi edit --apply "

# rlos rom
alias rlos="cd ~/rlos-workspace/"
alias rr="cd ~/Work/rlos-rom/"
alias bota="cd ~/rlos-workspace/ota/"
alias ota="cd /media/wd-4tb-1/rlos-workspace/ota/"

# app
alias rp="cd ~/Work/rlapp-platform/"
alias rais="cd ~/Work/rlapp-aistudio/"
alias ragw="cd ~/Work/rlai-gateway"

# tailscale
# thome = profile 3d7a (banyarnaing123@gmail.com), twork = profile fa4f (reezlive.com)
# Switch by stable profile ID, not account name, so no re-auth is triggered.
alias thome="tailscale switch 3d7a; tailscale up --accept-routes --operator=banyar; sudo /usr/local/bin/tailscale-lan-bypass"
alias twork="tailscale switch fa4f; tailscale up --accept-routes --operator=banyar; sudo /usr/local/bin/tailscale-lan-bypass"


# util
alias lanip="~/.local/bin/lanip.sh"
alias wanip="~/.local/bin/wanip.sh"

# z: an all-lowercase query matches case-insensitively, and a folder whose
# NAME is the query beats a higher-frecency path that merely contains it.
# Without this, `z work` (and omarchy's `cd work`) jumped to
# ~/rlos-workspace/rlos-rom instead of ~/Work.
ZSHZ_CASE=smart
# Wrap zshz itself: omarchy's zd baked `zshz` in at definition time, so
# wrapping the `z` alias alone would miss `cd`. Guarded because this file is
# sourced twice (by oh-my-zsh, then again after the omarchy aliases).
if (( $+functions[zshz] && ! $+functions[_zshz_orig] )); then
  functions -c zshz _zshz_orig
  zshz() {
    if (( $# == 1 )) && [[ $1 != -* && $1 != */* ]]; then
      local q=$1 line p best
      # -l lists matches lowest rank first, so the last name hit is the best.
      for line in "${(@f)$(_zshz_orig -l "$q" 2>/dev/null)}"; do
        p=/${line#*/}
        if [[ $q == ${q:l} ]]; then
          [[ ${p:t:l} == $q ]] && best=$p
        else
          [[ ${p:t} == $q ]] && best=$p
        fi
      done
      [[ -n $best && -d $best ]] && { builtin cd -- "$best"; return; }
    fi
    _zshz_orig "$@"
  }
fi

# make a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }


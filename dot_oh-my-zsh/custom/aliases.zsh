# environment paths
export PATH=$HOME/.opencode/bin:$HOME/.local/bin:$PATH

alias reload="source ~/.zshrc"

alias edit-alias="chezmoi edit ~/.oh-my-zsh/custom/aliases.zsh && source ~/.zshrc"

# android debug bridge
alias a="adb "
alias ad="adb devices"
alias ak="adb kill-server"
alias grep_prop="adb shell getprop | grep "

# rockchip
alias rd="rkut ld"

# general
alias tree="tree -h"
alias cz="chezmoi edit "

# rlos rom
alias rlos-rom="cd ~/rlos-workspace/rlos-rom/"
alias rr="cd ~/rlos-workspace/rlos-rom/"
alias re="cd ~/rlos-workspace/essential-rlos-rom-repo/"
alias rlapp-platform="cd ~/rlapp-workspace/rlapp-platform/"
alias rp="cd ~/rlapp-workspace/rlapp-platform/"
alias bota="cd ~/rlos-workspace/ota/"
alias ota="cd /media/wd-4tb-1/rlos-workspace/ota/"
alias mota="mv ~/rlos-workspace/ota/* /media/wd-4tb-1/rlos-workspace/ota"
alias dsd="cd /media/wd-4tb-1/rlapp-workspace/device-sample-data"

# tailscale
# thome = profile 3d7a (banyarnaing123@gmail.com), twork = profile fa4f (reezlive.com)
# Switch by stable profile ID, not account name, so no re-auth is triggered.
alias thome="tailscale switch 3d7a; tailscale up --accept-routes --operator=banyar; sudo /usr/local/bin/tailscale-lan-bypass"
alias twork="tailscale switch fa4f; tailscale up --accept-routes --operator=banyar; sudo /usr/local/bin/tailscale-lan-bypass"


# util
alias lanip="~/.local/bin/lanip.sh"
alias wanip="~/.local/bin/wanip.sh"

# make a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Push to Folders on Device via ADB
adb-push-update-zip() { adb push "$1" /storage/emulated/0/update.zip }
# accepts multiple files/folders: adb-push-to-Download ~/roms/*.zip mydir
adb-push-to-Download() {
  (( $# )) || { echo "usage: adb-push-to-Download <file-or-dir>..." >&2; return 1; }
  adb push -- "$@" /storage/emulated/0/Download/
}

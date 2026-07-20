# environment paths
export PATH=$HOME/.opencode/bin:$HOME/.local/bin:$PATH

alias reload="source ~/.zshrc"

alias ai="sudo apt-get install -y "
alias au="sudo apt-get update && sudo apt-get upgrade -y && sudo apt autoremove --purge -y"

alias edit-alias="vim ~/.oh-my-zsh/custom/aliases.zsh"

# android debug bridge
alias a="adb "
alias ad="adb devices"
alias ak="adb kill-server"
alias grep_prop="adb shell getprop | grep "

# rockchip
alias rd="rkut ld"
alias rft="rkut uf ~/rlos-workspace/rlos-rom/rockdev/Image-rlgen2/update.img"
alias rftp="rkut uf ~/rlos-workspace/rlos-rom/rockdev/Image-rlgen2plus/update.img"

# general
alias tree="tree -h"

# rlos rom
alias rlos-rom="cd ~/rlos-workspace/rlos-rom/"
alias rr="cd ~/rlos-workspace/rlos-rom/"
alias re="cd ~/rlos-workspace/essential-rlos-rom-repo/"
alias rlapp-platform="cd ~/rlapp-workspace/rlapp-platform/"
alias rp="cd ~/rlapp-workspace/rlapp-platform/"
alias ota="cd /media/wd-4tb-1/rlos-workspace/ota/"
alias dsd="cd /media/wd-4tb-1/rlapp-workspace/device-sample-data"

# tailscale
alias thome="tailscale switch banyarnaing123@gmail.com; tailscale up --accept-routes --operator=banyar"
alias twork="tailscale switch dev@reezlive.com; tailscale up --accept-routes --operator=banyar"


# util
alias lanip="~/.local/bin/lanip.sh"
alias wanip="~/.local/bin/wanip.sh"

# make a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

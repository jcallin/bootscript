#
# Meant to be sourced after bootscript.sh is run on Mac
# See .zshrc-windows for WSL2/Debian additions
#

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
 source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -----------------------------------------------------------------------------
# Initial setup
# -----------------------------------------------------------------------------


# Set or add to path if required
#export PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
# Place user scripts here
export PATH=$PATH:$HOME/bin

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'

#
# zsh configuration
#

alias ec="$EDITOR $HOME/.zshrc" # edit .zshrc
alias sc="source $HOME/.zshrc"          # reload zsh configuration

# Enable reverse search explicitly
bindkey '^R' history-incremental-search-backward

setopt histignorealldups sharehistory

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history

# zplug - manage plugins
source /usr/share/zplug/init.zsh
zplug "plugins/sudo", from:oh-my-zsh
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/sudo", from:oh-my-zsh
zplug "plugins/command-not-found", from:oh-my-zsh
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-completions"
zplug "junegunn/fzf"
zplug "romkatv/powerlevel10k", as:theme, depth:1

# zplug - install/load new plugins when zsh is started or reloaded
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
zplug load # --verbose


# Refresh bash profile with any changes
alias ref='source ~/.zshrc'
alias viz='vi ~/.zshrc'

# List aliases
function helpme() {
        if [ "$#" -ne 1 ]; then
                cat ~/.zshrc | grep -B 1 "alias\|function";
        elif [ "$#" -e 1 ]; then
                echo $(helpme) | grep $1
        else
                echo "Too many arguments";
        fi
}

# Fix for "sed: RE error: illegal byte sequence"
# https://stackoverflow.com/questions/19242275/re-error-illegal-byte-sequence-on-mac-os-x
export LC_ALL=C

# -----------------------------------------------------------------------------
# Visual and terminal usability
# -----------------------------------------------------------------------------

# use vim
set -o vi

# Configure standard editor variables
export VISUAL=vim
export EDITOR="$VISUAL"

# -----------------------------------------------------------------------------
# Commands and aliases
# -----------------------------------------------------------------------------

export SBT_OPTS="-XX:+CMSClassUnloadingEnabled -Xms4G -Xmx8G -Xss1M"
alias s='sbt -jvm-debug 5001'

alias swagger-editor='docker pull swaggerapi/swagger-editor && docker run -p 80:8080 -d swaggerapi/swagger-editor'

# Python3 as default
alias python='python3'

# Style ls
export LSCOLORS=GxFxCxDxBxegedabagaced
alias l='ls -lhGa'
alias ls=l

# Common shortcuts
alias v='vim'
alias vimrc='v ~/.vimrc'

# Navigation
alias ..="cd .."
alias ..2="cd ../../"
alias ..3="cd ../../../"
alias ..4="cd ../../../../"
alias back='cd -'
alias ~='cd ~'

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
# 
# WORKFLOW: https://gist.github.com/jcallin/6ecaccc63adaa23a7dd51c483d7facca

# We will squash into master locally, but _push_ the result to our feature branch on remote. This way we can easily open a PR for the squashed commit.
        # git checkout branch
# Set HEAD back to origin/master so we can merge to the correct place on remote, but keep local changes to master intact if we have them
        # git reset --hard origin/master
# Merge our branch to current head (origin/master set from last command). Squash to one commit.
        # git merge --squash origin/branch
# In the merge commit, include all commits to the branch
        # git commit --no-edit
# Push the squashed commit on branch so we can open a PR
        # git push --force-with-lease

#
# Useful commands
#
# Update a non-checked-out branch: `git fetch origin master:master` (while on dev, etc)
# Change the commit a branch points to: `git checkout branch-name && git reset --hard new-tip-commit`
#                                       `git branch -f branch-name new-tip-commit
# Rename a branch                      : git branch -m new-name
# 
#

function run-squash-merge() {
    currentBranch=get-current-branch
    git reset --hard origin/master
    git merge --squash "origin/$currentBranch"
    git commit --no-edit
    git push --force-with-lease
}

function get-current-branch() {
    echo $(git branch | grep \* | cut -d ' ' -f2)
}

# Get the state of a file from a commit (alternative to cherry-picking)
function get-file-at-commit() {
    filepath="$1"
    commit="$2"
    git checkout $commit $filepath
}

# Similar to above, but from a branch
function get-file-at-branch() {
    filepath="$1"
    branch="$2"
    git checkout $branch $filepath
}

# Compares the list of remote branch (git branch -r) to the list of branch with their remote
# tracking branch (git branch -vv). The diff of these 2 lists will give a list of local branches
# that have been deleted on the remote and are safe to remove with `git branch -d`
function gfp() {
    while true; do
        read -p "!!WARNING!! Running this command will remove any branches you have locally, but which you have not pushed to remote yet! (no remote tracking branch).
        Are you sure you want to continue? Push any branches you believe should be backed up on the remote: " yn
        case $yn in
            [Yy]* ) $(runGfp); break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

function runGfp() {
    git fetch --all && git fetch --prune --progress && git branch --remotes | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -D;
}

# Delete all refs to branches in remote which no longer exist on remote
alias gpr='git remote update origin --prune'

# Delete all local branches that have been merged to current branch
alias gcleanb='git branch --merged master | grep -v "^[ *]*master$" | xargs git branch -d'
# alias gcleanb='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -D'

function gs() { git log --all --full-history -- "**/${1}.*"; }

# See recent branches worked on
# awk substring example
function gr() {
    # Get recent branches
    branches=$(git for-each-ref --sort=-committerdate refs/heads/ | awk -F' ' '{print substr($1, 1, length($1)-30), $3;}' | head -n 7)
    # Remove /refs/head from start of branch name
    printf '%s\n' "${branches//refs\/heads\/}" | \
        # Number each branch to reference in gcon()
        nl -w2 -s" ";
}

function gdm() {
    # Diff a file in a branch against master
    git diff "master:$1 $1"
}

function ga() { git add "$@"; }

alias g='git status'
alias gba='git branch -a'
alias gl='git log'
alias glv='git log --graph --decorate --all --pretty=oneline --abbrev-commit'
# show the parent commit of a commit
function show-parent-commit() { git log --pretty=%P -n 1 "$1"; }

alias gc='git commit -m'
alias gam='git commit --amend'
alias gcam='git commit --amend -m'
function gcp() { git cherry-pick "$1"; }

alias gpl='git pull'
alias gfa='git fetch --all'
# Dangerous
#&& gfp'
alias gpsh='git push'
alias gpshf='git push --force'

# Remove a branch from remote origin
function gpd() { git push -d origin "$1"; }
function gbD() { git branch -D "$1"; }

alias gco='git checkout'
# Check out a branch number from recent branches. Use gr() to get branch numbers
function gcon() {
    # Get recent branches
    branch=$(gr | \
    # Trim whitespace
    tr -s ' ' | \
    # Separate by whitespace, extract the branch names
    cut -d ' ' -f 4 | \
    # Get the branch name on the line we want
    sed "$1q;d")
    gco "$branch";
}
function grb() { git rebase "$1"; }
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbs='git rebase --skip'
alias grbm='git rebase master'
alias gma='git merge --abort'
alias gmm='git merge master'
alias grv='git checkout --'
alias gcd='git checkout develop'
alias gcm='git checkout master'
alias gcob='git checkout -b'
alias gd='git diff'
alias grs='git reset HEAD'
alias grs1='git reset HEAD~1'
alias gst='git stash'
alias gsp='git stash pop'
# WIP better stashes
# function gst() { git stash push -m "$(get-current-branch)-$(git rev-parse --short HEAD)"; }
alias gs='git stash'
alias gss='git stash show'
alias gsl='git stash list'

# Delete local remote-tracking branches (doesn't delete locally. see gfp())
alias gpr='git remote prune origin'

# -----------------------------------------------------------------------------
# Docker
# -----------------------------------------------------------------------------
alias di='docker images'
alias dps='docker ps'
alias dpa='docker ps -a'
alias ds='docker stop '
alias drmi='docker rmi'

function dl() { docker logs "$1"; }

# Copy a file from a container to host
# docker cp <containerId>:/file/path/within/container /host/path/target

# Open a shell in running container
function de() { docker exec -i -t "$1" /bin/sh; }
# Open a shell, overwriting entrypoint
function dre() { docker run -it --entrypoint /bin/sh; }
# Remove dangling images
function drd() { docker rmi $(docker images --filter "dangling=true" -q --no-trunc); }
# Remove stopped container
function drm() { docker rm "$1"; }
# Stop and remove a container
function dsrm() { docker stop "$1" && docker rm "$1"; }
# Remove images with same name that are tagged differently
function drmif() { docker images | grep "$1" | awk '{print $1 ":" $2}' | xargs docker rmi -f; }
# Stop and remove all containers
function drma() {
        ps_out=`docker ps -a | tail -n +2 | awk '{print $1}'`
        echo $ps_out | xargs docker stop;
        echo $ps_out | xargs docker rm;
}


#
# Examples
#

# Find all files called logback-test.xml and replace their content with the contet of /tmp/logback-test.xml
# find . -name "logback-test.xml" -exec sh -c "cat /tmp/logback-test.xml > {}" \;

#
# End Stuff
#

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="~/.sdkman"
[[ -s "~/.sdkman/bin/sdkman-init.sh" ]] && source "~/.sdkman/bin/sdkman-init.sh"

# -----------------------------------------------------------------------------
# Initial setup
# -----------------------------------------------------------------------------

# Import environment variables and sensitive stuff
source ~/.env_vars

# Refresh bash profile with any changes
alias ref='source ~/.bashrc'
alias vib='vi ~/.bashrc'

# List aliases
function helpme() {
        if [ "$#" -ne 1 ]; then
                cat ~/.bashrc | grep -B 1 "alias\|function";
        elif [ "$#" -e 1 ]; then
                echo $(helpme) | grep $1
        else
                echo "Too many arguments";
        fi
}

# Path additions
export PATH=$PATH:$HOME/bin

# Fix for "sed: RE error: illegal byte sequence"
# https://stackoverflow.com/questions/19242275/re-error-illegal-byte-sequence-on-mac-os-x
export LC_ALL=C

# Use VI in BASH
# CTRL+a and CTRL+e are habit for me right now so off by default
# set -o vi

# -----------------------------------------------------------------------------
# Visual and terminal usability
# -----------------------------------------------------------------------------

# Use the \[ escape to begin a sequence of non-printing characters,
# and the \] escape to signal the end of such a sequence.
# Define some colors first:
# High Intensty
IBlack='\[\033[0;90m\]'       # Black
IRed='\[\033[0;91m\]'         # Red
IGreen='\[\033[0;92m\]'       # Green
IYellow='\[\033[0;93m\]'      # Yellow
IBlue='\[\033[0;94m\]'        # Blue
IPurple='\[\033[0;95m\]'      # Purple
ICyan='\[\033[0;96m\]'        # Cyan
IWhite='\[\033[0;97m\]'       # White
NC='\[\033[0m\]'

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;
# Append to the Bash history file, rather than overwriting it
shopt -s histappend;
# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Color the CLI
export CLICOLOR=1
# Larger history
HISTSIZE=10000

# Prompt formatting with git branch
# WIP -- errors when you are in /Users directory
function workdir_short() {
    wd=$(pwd | awk -F\/ '{ print $(NF-2),"/",$(NF-1),"/",$(NF) }' | tr -d ' ')
    wd1=${wd/Users\/callin/\~}
    echo ${wd1/callin/\~}
}

# For full working directory, use \\w
# Backslash in fron of workdir_short command makes it execute every time
# Use function like \$(workdir_short)
# Note: this causes unexpected terminal behavior if used in PS1, so I've turned it off
#symbol="∇"
export PS1="${IBlue}\\u ${IYellow}[\\w] ${IPurple}\$(parse_git_branch) ${IGreen}$ ${NC}"
parse_git_branch() {
     branch_chars=11
     git_branch_result=$(git branch 2> /dev/null)
     if [[ $? -ne 0 ]];
     then
         echo "no git"
     else
         # Print the full branch name if it's short, else print a short one + ..
         git_branch_parsed=$(echo "$git_branch_result" | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/' | head -c $branch_chars)
         if [[ $(echo $git_branch_parsed | head -c 12 | wc -c) -gt $branch_chars ]];
         then
             echo "$git_branch_parsed.."
         else
             echo "$git_branch_parsed"
         fi
     fi
}

# -----------------------------------------------------------------------------
# Commands and aliases
# -----------------------------------------------------------------------------

alias swagger-editor='docker pull swaggerapi/swagger-editor && docker run -p 80:8080 -d swaggerapi/swagger-editor'

# Python3 as default
alias python='python3'

# Update chromecast
alias chromecast_update='curl -X POST -H "Content-Type: application/json" -d "{"params": "ota foreground"}" http://192.168.1.110:8008/setup/reboot -v'

# Style ls
export LSCOLORS=GxFxCxDxBxegedabagaced
alias l='ls -lhGa'
alias ls='l'

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

# My scripts
alias bart='/Users/callin/Documents/programming/play_scripts/next_bart.py'

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
    commit="$1"
    filepath="$2"
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
function gfp() { git fetch -p --progress && git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d; }

# Delete all refs to branches in remote which no longer exist on remote
alias gpr='git remote update origin --prune'

# Delete all local branches that have been merged to current branch
alias gcleanb='git branch --merged master | grep -v "^[ *]*master$" | xargs git branch -d'
# alias gcleanb='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -D'

function gs() { git log --all --full-history -- "**/${1}.*"; }

# See recent branches worked on
# awk substring example
function gr() {
    branches=$(git for-each-ref --sort=-committerdate refs/heads/ | awk -F' ' '{print substr($1, 1, length($1)-30), $3;}' | head -n 5)
    # Remove /refs/head from start of branch name
    printf '%s\n' "${branches//refs\/heads\/}" | \
        # Number each commit to reference in gcon()
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

# Remove a branch from remote origin
function gpd() { git push -d origin "$1"; }

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
    gco $branch;
}
alias grv='git checkout --'
alias gcd='git checkout develop'
alias gcm='git checkout master'
alias gcob='git checkout -b'
alias gd='git diff'
alias grs='git reset HEAD'
alias gst='git stash'
# WIP better stashes
# function gst() { git stash push -m "$(get-current-branch)-$(git rev-parse --short HEAD)"; }
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
# Run a container in priv mode with fuse compat
function dr_fuse() { docker run --device /dev/fuse --privileged -d "$1"; }
# Remove dangling images
function drd() { docker rmi $(docker images --filter "dangling=true" -q --no-trunc); }
# Remove stopped container
function drm() { docker rm "$1"; }
# Stop and remoave a container
function dsrm() { docker stop "$1" && docker rm "$1"; }
# Remove images with same name that are tagged differently
function drmif() { docker images | grep "$1" | awk '{print $1 ":" $2}' | xargs docker rmi -f; }
# Stop and remove all containers
function drma() {
        ps_out=`docker ps -a | tail -n +2 | awk '{print $1}'`
        echo $ps_out | xargs docker stop;
        echo $ps_out | xargs docker rm;
}

# SSH
alias dev='ssh ubuntu@callin-dev'

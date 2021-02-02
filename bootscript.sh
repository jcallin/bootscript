#!/usr/bin/env/bash

#
# Designed for Mac or Debian/WSL 2. Only requires bash
#

# Setup ssh
if [ ! -d .ssh ]
then
    echo "Please copy your ssh configuration (private + public keys, config) to a .ssh directory in the script dir"
    exit 1
fi

mkdir ~/.ssh
cp -r .ssh ~/.ssh

read -p "Are you using Mac?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  /usr/bin/env/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install git zip unzip vim curl man zsh
else
  # Update the system
  sudo apt-get update
  # Install things we need
  sudo apt-get install -y git zip unzip vim curl man
  # use zsh as default shell
  apt install zsh
fi

chsh -s "$(which zsh)"

# Use git.exe if we're in a windows dir or git if we're in a linux dir. This is useful if running
# WSL 2 where file ops/git ops are super slow
# checks to see if we are in a windows or linux dir
function isWinDir {
  case $PWD/ in
    /mnt/*) return "$(true)";;
         *) return "$(false)";;
  esac
}
# wrap the git command to either run windows git or linux. Git runs super slow in wsl2
function git {
  if isWinDir
  then
    echo "If this command fails, you don't have git.exe installed on windows and you should install it"
    git.exe "$@"
  else
    /usr/bin/git "$@"
   fi
}

# Setup zsh profile
mkdir -p ~/Programming

# Setup vim
git clone git@github.com:jcallin/vimrc.git ~/Programming
cp ~/Programming/vimrc/.vimrc ~/Programming/.vimrc
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# Configure git also for windows
read -p "Configure git for Windows as well?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  git config --global core.autocrlf false
  git config --global core.eol lf
fi

read -p "Enter an email address for global git config" -r email
echo
git config --global user.email "$email"

git config --global user.name "Julian Callin"
git config --global core.editor "vim"

# optional software
read -p "Install SDKMan, Java 11, Scala, and sbt for JDK management?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -s "https://get.sdkman.io" | bash
    sdk install java 11.0.9-adpt
    sdk install scala
    sdk install sbt
fi

read -p "Install nvm for Node version management?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.0/install.sh | bash
fi

# Link ~/.zshrc and ~/.env_vars to this repo
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")
ln -s "${SCRIPT_PATH}"/.zshrc ~/.zshrc >/dev/null 2>&1
ln -s "${SCRIPT_PATH}"/.env_vars ~/.env_vars >/dev/null 2>&1

echo "There are a couple of manual steps required!"
echo "- Open a new zsh terminal and run 'source /path/to/this/repo/.zshrc' to use zsh"
echo "- Vim plugins need to be installed manually. Enter vim and run :PluginInstall"


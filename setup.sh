#!/usr/bin/env zsh
# This symlinks all the dotfiles to ~/
# This is safe to run multiple times and will prompt you about anything unclear

# Utils
ask_for_confirmation() {
  while true; do
    read "?$(print_question "$1")" yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes or no.";;
    esac
  done
  unset yn
}

ask_for_sudo() {
  # Ask for the administrator password upfront
  sudo -v

  # Update existing `sudo` time stamp until this script has finished
  # https://gist.github.com/cowboy/3118588
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done &> /dev/null &
}

execute() {
  eval $1
  print_result $? "${2:-$1}"
}

print_error() {
  # Print output in red
  printf "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_info() {
  # Print output in purple
  printf "\n\e[0;35m $1\e[0m\n\n"
}

print_question() {
  # Print output in yellow
  printf "\e[0;33m  [?] $1\e[0m"
}

print_result() {
  [ $1 -eq 0 ] \
    && print_success "$2" \
    || print_error "$2"

  [[ "$3" == "true" ]] && [ $1 -ne 0 ] \
    && exit
}

print_success() {
  # Print output in green
  printf "\e[0;32m  [✔] $1\e[0m\n"
}

# Warn user this script will overwrite current dotfiles
if ! ask_for_confirmation "?Warning: this will overwrite your current dotfiles. Continue? [y/n] "; then
  exit 1
fi
# Get the dotfiles directory's absolute path
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"


dir=~/dotfiles                        # dotfiles directory
dir_backup=~/dotfiles_old             # old dotfiles backup directory

# Get current dir (so run this script from anywhere)

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DOTFILES_DIR

# Create dotfiles_old in homedir
echo -n "Creating $dir_backup for backup of any existing dotfiles in ~..."
mkdir -p $dir_backup
echo "done"

# Change to the dotfiles directory
echo -n "Changing to the $dir directory..."
cd $dir
echo "done"

#
# Actual symlink stuff
#


declare -a FILES_TO_SYMLINK=(
  'shell/shell_aliases'
  'shell/shell_config'
  'shell/shell_exports'
  'shell/shell_functions'
  'shell/zshrc'
  'shell/ackrc'
  'shell/curlrc'
  'shell/gemrc'
  'shell/inputrc'
  'shell/screenrc'

  'git/gitattributes'
  'git/gitconfig'
  'git/gitignore'
)

# FILES_TO_SYMLINK="$FILES_TO_SYMLINK .vim bin" # add in vim and the binaries

# Move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files

echo "Moving any existing dotfiles from ~ to $dir_backup"
for i in ${FILES_TO_SYMLINK[@]}; do
  mv ~/.${i##*/} ~/dotfiles_old/ >/dev/null 2>&1
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function mklink() {
  local sourceFile=$1
  local targetFile=$2
  
  if [ ! -e "$targetFile" ]; then
    execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
  elif [[ "$(readlink "$targetFile")" == "$sourceFile" ]]; then
    print_success "$targetFile → $sourceFile"
  else
    if ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"; then
      rm -r "$targetFile"
      execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
    else
      print_error "$targetFile → $sourceFile"
    fi
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

  local i=''
  local sourceFile=''
  local targetFile=''

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  for i in ${FILES_TO_SYMLINK[@]}; do

    sourceFile="$(pwd)/$i"
    targetFile="$HOME/.$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"
    
    mklink "$sourceFile" "$targetFile"
  done


  unset FILES_TO_SYMLINK

  # Copy binaries
  #ln -fs $HOME/dotfiles/bin $HOME

  #declare -a BINARIES=(
  #)

  #for i in ${BINARIES[@]}; do
  #  echo "Changing access permissions for binary script :: ${i##*/}"
  #  chmod +rwx $HOME/bin/${i##*/}
  #done

  #unset BINARIES
}

vim_setup () {
  # copy vim
  mkdir -p $HOME/.vim
  mklink $HOME/dotfiles/vim/vimrc $HOME/.vim/vimrc
  if test \! -d $HOME/.vim/bundle/Vundle.vim/.git; then
    echo "Installing Vundle"
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
  fi

  # nvim
  ln -fs $HOME/.vim $HOME/.config/nvim
  ln -fs vimrc $HOME/.vim/init.vim

  echo "Updating Vundle plugins..."
  nvim +PluginUpdate +qall >/dev/null 2>&1
  print_result $? "Updated"
}

install_zsh () {
  # Test to see if zshell is installed.  If it is:
  if [ -f /bin/zsh -o -f /usr/bin/zsh ]; then
    # Install Oh My Zsh if it isn't already present
    if [[ ! -d $HOME/.oh-my-zsh/ ]]; then
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
    # Set the default shell to zsh if it isn't currently set to zsh
    if [[ ! $(basename $SHELL) == "zsh" ]]; then
      chsh -s $(which zsh)
    fi
  else
    # If zsh isn't installed, get the platform of the current machine
    platform=$(uname);
    # If the platform is Linux, try an apt-get to install zsh and then recurse
    if [[ $platform == 'Linux' ]]; then
      if [[ -f /etc/redhat-release ]]; then
        sudo yum install zsh
        install_zsh
      fi
      if [[ -f /etc/debian_version ]]; then
        sudo apt-get install zsh
        install_zsh
      fi
    # If the platform is OS X, tell the user to install zsh :)
    elif [[ $platform == 'Darwin' ]]; then
      echo "We'll install zsh, then re-run this script!"
      brew install zsh
      exit
    fi
  fi
}

###################################
print_info "Fetching submodules"
git submodule update --quiet --init --recursive
print_result $? "Submodules fetched"

main
vim_setup
install_zsh
###################################
#
###############################################################################
# Zsh                                                                         #
###############################################################################

# Install Zsh settings
mklink ~/dotfiles/zsh-custom/themes $HOME/.oh-my-zsh/custom/themes
mklink ~/dotfiles/zsh-custom/plugins $HOME/.oh-my-zsh/custom/plugins

###############################################################################
# Terminal & iTerm 2                                                          #
###############################################################################

# Only use UTF-8 in Terminal.app
#defaults write com.apple.terminal StringEncodings -array 4

# Install the Solarized Dark theme for iTerm
#open "${HOME}/dotfiles/iterm/themes/Solarized Dark.itermcolors"

# Don’t display the annoying prompt when quitting iTerm
#defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# Reload zsh settings
source ~/.zshrc

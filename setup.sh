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

print_log() {
  printf "$1"
  printf "$1" |\
    sed "s/\x1B\[\([0-9]\{1,2\}\(;[0-9]\{1,2\}\)\?\)\?[mGK]//g"\
    >>setup.log
}

execute() {
  eval $1 >>setup.log 2>&1
  print_result $? "${2:-$1}"
}

print_error() {
  # Print output in red
  print_log "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_info() {
  # Print output in purple
  print_log "\e[0;35m  $1\e[0m\n"
}

print_question() {
  # Print output in yellow
  print_log "\e[0;33m  [?] $1\e[0m"
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
  print_log "\e[0;32m  [✔] $1\e[0m\n"
}

mklink () {
  local sourceFile="$1"
  local targetFile="$2"
  local backupToDir="$3"

  if [ -d "$backupToDir" ]; then
    backupTo="$backupToDir/$(basename "$targetFile")"
  fi

  if [ ! -e "$targetFile" ]; then
    execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
  elif [[ "$(readlink "$targetFile")" == "$sourceFile" ]]; then
    print_success "$targetFile → $sourceFile"
  else
    if [ ! -z "$backupTo" ]; then
      print_success "Backup'd $targetFile → $backupTo"
      execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
    elif ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"; then
      rm -r "$targetFile"
      execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
    else
      print_error "$targetFile → $sourceFile"
    fi
  fi
}

# empty logfile
: >'setup.log'

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
print_info "Creating $dir_backup for backup of existing dotfiles in ~"
mkdir -p $dir_backup

# Change to the dotfiles directory
cd $dir

# Fetch submodules
print_info "Fetching submodules"
git submodule update --quiet --init --recursive
print_result $? "Submodules fetched"

# Brew stuff
if ask_for_confirmation "?Install pkgs (pip3, brew, cask, mas)?"; then
  if [ "$(uname)" = "Darwin" ]; then
    if ! type "brew" >/dev/null; then
      print_error "No homebrew found, skipping"
    else
      execute "brew tap Homebrew/bundle"
      execute "brew bundle --file=packages/Brewfile" "Homebrew & Cask & Mac AppStore"
    fi
  fi
  execute "pip3 install -U -r packages/requirements3.txt" "pip3"
fi

# Actual symlink stuff
FILES_TO_SYMLINK=(
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

# Move any existing dotfiles in homedir to dotfiles_old directory, then
# create symlinks from the homedir to any files in the ~/dotfiles
# directory specified in $files
for i in ${FILES_TO_SYMLINK[@]}; do
  sourceFile="$PWD/$i"
  targetFile="$HOME/.$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"
  mklink "$sourceFile" "$targetFile" "$dir_backup"
done

unset FILES_TO_SYMLINK

# Vim
mkdir -p $HOME/.vim
mklink $HOME/dotfiles/vim/vimrc $HOME/.vim/vimrc
if test \! -d $HOME/.vim/bundle/Vundle.vim/.git; then
  echo "Installing Vundle"
  git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
fi

# nvim
ln -fs $HOME/.vim $HOME/.config/nvim
ln -fs vimrc $HOME/.vim/init.vim

print_info "Updating Vundle plugins..."
vim +PluginUpdate +qall >/dev/null 2>&1
print_result $? "Updated"


# recursive mklink
recursive_link () {
  for f in $1/*; do
    fname="$(basename "$f")"
    if [ \! -L "$2/$fname" -a -d "$2/$fname" -a -d "$f" ]; then
      # dir to dir
      recursive_link "$f" "$2/$fname"
    else
      mklink "$f" "$ZSH_CUSTOM/$(basename "$f")"
    fi
  done
}

# Oh My Zsh Customs
if [ -z "$ZSH_CUSTOM" ]; then
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
fi
recursive_link ~/dotfiles/zsh-custom "$ZSH_CUSTOM"

# Oh My Zsh Theme
if [ "$(uname)" = "Darwin" ]; then
  mklink $HOME/.oh-my-zsh/custom/powerlevel9k.theme $HOME/.oh-my-zsh/custom/zsh.theme
fi

# Reload zsh settings
source ~/.zshrc

# would fail if dir is not empty
if rmdir $dir_backup >/dev/null 2>&1; then
  print_info "Removed $dir_backup since no files were backed up"
fi

print_info "Done. You can check $PWD/setup.log for logs."

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

print_log() {
  printf "$1"
  printf "$1" |\
    sed "s/\x1B\[\([0-9]\{1,2\}\(;[0-9]\{1,2\}\)\?\)\?[mGK]//g"\
    >>"$LOGFILE"
}

execute() {
  echo "$ EVAL $1" >>"$LOGFILE"
  ( eval $1 ) >>"$LOGFILE" 2>&1
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
  print_log "\e[0;33m  [?] $1 [y/n] \e[0m"
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
    execute "ln -fs \"$sourceFile\" \"$targetFile\"" "$targetFile → $sourceFile"
  elif [[ "$(readlink "$targetFile")" == "$sourceFile" ]]; then
    print_success "$targetFile → $sourceFile"
  else
    if [ ! -z "$backupTo" ]; then
      mkdir -p "$backupToDir"
      execute "mv \"$targetFile\" \"$backupTo\"" "Backup'd $targetFile → $backupTo"
      execute "ln -fs \"$targetFile\" \"$sourceFile\"" "$targetFile → $sourceFile"
    elif ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"; then
      rm -r "$targetFile"
      execute "ln -fs \"$sourceFile\" \"$targetFile\"" "$targetFile → $sourceFile"
    else
      print_error "$targetFile → $sourceFile"
    fi
  fi
}

# Get current dir (so run this script from anywhere)
DOTFILES_DIR="$(cd "$(dirname "$0")"; pwd -P)"
export DOTFILES_DIR

# Change to the dotfiles directory
cd "$DOTFILES_DIR"
print_info "Workdir: $PWD"

LOGFILE="$PWD/"$LOGFILE""
# empty logfile
: >"$LOGFILE"

# Warn user this script will overwrite current dotfiles
if ! ask_for_confirmation "Warning: this will overwrite your current dotfiles. Continue?"; then
  exit 1
fi

BACKUP_DIR=~/dotfiles_old             # old dotfiles backup directory

# Create dotfiles_old in homedir
print_info "Creating $BACKUP_DIR for backup of existing dotfiles in ~"
mkdir -p "$BACKUP_DIR"


# Fetch submodules
print_info "Fetching submodules"
execute "git submodule update --quiet --init --recursive"

# Oh My Zsh install
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if ask_for_confirmation "Install oh-my-zsh?"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh); exit"
  else
    print_error "Oh My Zsh is not installed!"
    exit 1
  fi
fi

# Brew stuff
if ask_for_confirmation "Install pkgs (brew/cask/mas, pip3, npm, vscode)?"; then
  pushd packages
  if [ "$(uname)" = "Darwin" ]; then
    if ! type "brew" >/dev/null; then
      print_error "No homebrew found, skipping"
    else
      execute "brew tap Homebrew/bundle"
      execute "brew bundle --file=Brewfile" "Homebrew & Cask & Mac AppStore"
    fi
  fi

  execute "pip3 install -U -r requirements3.txt" "pip3"
  
  execute "<npm-list.txt xargs npm i -g" "npm"
  
  if command -v code >/dev/null; then
    print_info "Installing VSCode extensions, this might take a while..."
    execute "<vscode-list.txt xargs -n1 code --install-extension" "vscode"
  fi
  popd
fi
exit 0
# Actual symlink stuff
FILES_TO_SYMLINK=(
  'shell/shell_aliases'
  'shell/shell_config'
  'shell/shell_exports'
  'shell/shell_functions'
  'shell/zshrc'
  'shell/curlrc'
  'shell/inputrc'

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
  mklink "$sourceFile" "$targetFile" "$BACKUP_DIR"
done

unset FILES_TO_SYMLINK

# Vim
mkdir -p $HOME/.vim
mklink "$DOTFILES_DIR/vim/vimrc" "$HOME/.vim/vimrc"

HAVE_VUNDLE=1
if test \! -d $HOME/.vim/bundle/Vundle.vim/.git; then
  if ask_for_confirmation "Install Vundle? (vimrc might break without it)"; then
    execute "git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim"
  else
    HAVE_VUNDLE=0
  fi
fi

mkdir -p $HOME/.config

# nvim
ln -fs $HOME/.vim $HOME/.config/nvim
ln -fs vimrc $HOME/.vim/init.vim

if [ $HAVE_VUNDLE = 1 ] && ask_for_confirmation "Update Vundle plugins?"; then
  execute "vim +PluginUpdate +qall >/dev/null 2>&1"
fi

# recursive mklink
recursive_link () {
  for f in $1/*; do
    fname="$(basename "$f")"
    if [ \! -L "$2/$fname" -a -d "$2/$fname" -a -d "$f" ]; then
      # dir to dir
      recursive_link "$f" "$2/$fname" "$3/$fname"
    else
      mklink "$f" "$2/$fname" "$3"
    fi
  done
}
# Oh My Zsh Customs
if [ -z "$ZSH_CUSTOM" ]; then
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
fi
recursive_link "$DOTFILES_DIR/zsh-custom" "$ZSH_CUSTOM"

# Oh My Zsh Theme
if [ "$(uname)" = "Darwin" ]; then
  mklink "$HOME/.oh-my-zsh/custom/powerlevel9k.theme" "$HOME/.oh-my-zsh/custom/zsh.theme"
fi

# VSCode
if command -v code >/dev/null && [ "$(uname)" = "Darwin" ]; then
  VSC_USER_DATA="$HOME/Library/Application Support/Code/User"

  print_info "(macOS) VSCode found"

  print_info "Linking user data"
  recursive_link "$DOTFILES_DIR/vscode" "$VSC_USER_DATA" "$BACKUP_DIR/vscode"
fi

# Reload zsh settings
source ~/.zshrc

# would fail if dir is not empty
if rmdir "$BACKUP_DIR" >/dev/null 2>&1; then
  print_info "Removed $BACKUP_DIR since no files were backed up"
fi

print_info "Done. You can check $LOGFILE for logs."

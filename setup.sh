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

LOGFILE="$PWD/setup.log"
# empty logfile
: >"$LOGFILE"

print_info "Workdir: $PWD"

# Warn user this script will overwrite current dotfiles
if ! ask_for_confirmation "Warning: this will overwrite your current dotfiles. Continue?"; then
  exit 1
fi

BACKUP_DIR=~/dotfiles_old

# Create dotfiles_old in homedir
print_info "Creating $BACKUP_DIR for backup of existing dotfiles in ~"
mkdir -p "$BACKUP_DIR"


# prezto install
if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
  if ask_for_confirmation "Install prezto?"; then
    execute "git clone --recursive https://github.com/sorin-ionescu/prezto.git '${ZDOTDIR:-$HOME}/.zprezto'"
  else
    print_error "prezto is not installed!"
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
      execute "brew bundle --file=Brewfile" "Homebrew & Cask & Mac AppStore & VSCode"
    fi
  fi

  execute "pip3 install -U -r requirements3.txt" "pip3"
  
  execute "<npm-list.txt xargs npm i -g" "npm"
  popd
fi

# Actual symlink stuff
FILES_TO_SYMLINK=(
  'zsh/zlogin'
  'zsh/zpreztorc'
  'zsh/zprofile'
  'zsh/zshenv'
  'zsh/zshrc'

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
  targetFile="$HOME/.$(basename "$i")"
  mklink "$sourceFile" "$targetFile" "$BACKUP_DIR"
done

unset FILES_TO_SYMLINK

# Vim
mkdir -p $HOME/.config/nvim
mklink "$DOTFILES_DIR/vim/vimrc" "$HOME/.config/nvim/init.vim"

HAVE_VIMPLUG=1
if test \! -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"; then
  if ask_for_confirmation "Install vim-plug? (vimrc might break without it)"; then
    execute "curl -fLo '${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim' --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  else
    HAVE_VIMPLUG=0
  fi
fi

if [ $HAVE_VIMPLUG = 1 ] && ask_for_confirmation "Update vim-plug plugins?"; then
  execute "nvim +PlugUpdate +qall >/dev/null 2>&1"
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

# VSCode
if [ "$(uname)" = "Darwin" ]; then
  if command -v code >/dev/null; then
    VSC_USER_DATA="$HOME/Library/Application Support/Code/User"
    print_info "Linking VS Code user data"
    recursive_link "$DOTFILES_DIR/vscode" "$VSC_USER_DATA" "$BACKUP_DIR/vscode"
  fi
  if command -v codium >/dev/null; then
    VSC_USER_DATA="$HOME/Library/Application Support/VSCodium/User"
    print_info "Linking VS Codium user data"
    recursive_link "$DOTFILES_DIR/vscode" "$VSC_USER_DATA" "$BACKUP_DIR/vscodium"
  fi
fi

# Reload zsh settings
source ~/.zshrc

# would fail if dir is not empty
if rmdir "$BACKUP_DIR" >/dev/null 2>&1; then
  print_info "Removed $BACKUP_DIR since no files were backed up"
fi

print_info "Done. You can check $LOGFILE for logs."

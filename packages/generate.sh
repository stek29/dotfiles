#!/usr/bin/env sh

# brew, cask, mas, vscode
brew bundle dump --force
grep 'tap ' Brewfile | sort >Brewfile.new
grep -v '^tap ' Brewfile | sort >>Brewfile.new
mv Brewfile.new Brewfile

# pip
pipdeptree 2>/dev/null |
  grep -E '^\w+' |
  grep -v wheel |
  sed 's/==.*$//' |
  sort \
    >requirements3.txt

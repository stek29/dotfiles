#!/usr/bin/env sh

# brew, cask, mas, vscode
brew bundle dump --no-go --no-cargo --file=Brewfile.new
grep 'tap ' Brewfile.new | sort >Brewfile
grep -v '^tap ' Brewfile.new | sort >>Brewfile
rm Brewfile.new

# pip
pipdeptree 2>/dev/null |
  grep -E '^\w+' |
  grep -v wheel |
  sed 's/==.*$//' |
  sort \
    >requirements3.txt

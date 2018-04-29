#!/usr/bin/env sh

# brew, cask, mas
brew bundle dump --force

# pip
pipdeptree 2>/dev/null |\
  grep -E '^\w+' |\
  grep -v wheel |\
  sed 's/==.*$//' |\
  sort \
    > requirements3.txt

# npm
npm -g ls --depth=0 --parseable |\
  tail -n +2 | # skip first line which is path to node_modules
  while read x; do
    echo $(basename $x)
  done \
    > npm-list.txt

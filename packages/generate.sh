# brew, cask, mas
brew bundle dump --force

# pip
pipdeptree 2>/dev/null |\
  grep -E '^\w+' |\
  grep -v wheel |\
  sed 's/==.*$//' |\
  sort \
    > requirements3.txt



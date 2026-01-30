# stek29's Dotfiles

The setup script is smart enough to back up your existing dotfiles into a `~/dotfiles_old/` directory if you already have any dotfiles of the same name as the dotfile symlinks being created in your home directory.

The install script will:

- back up any existing dotfiles in your home directory to `~/dotfiles_old/`
- create symlinks to the dotfiles in `~/dotfiles/` in your home directory
- clone the `prezto` repository from GitHub (for use with `zsh`)
- install Homebrew bundle packages (brew/cask/mas) on macOS if Homebrew is available
- install Python packages via `pip3`
- link VS Code user settings on macOS (if `code` is available)
- link Finicky config on macOS
- install `vim-plug` for Neovim and optionally update plugins

## Installation

```sh
$ git clone --recursive https://github.com/stek29/dotfiles.git ~/dotfiles
$ cd ~/dotfiles
$ ./setup.sh
```

## Customize

### Local Settings

The dotfiles can be easily extended to suit additional local
requirements by using the following files:

#### `~/.zsh.local`

If the `~/.zsh.local` file exists, it will be automatically sourced
after all the other [shell related files](shell), thus, allowing its
content to add to or overwrite the existing aliases, settings, PATH,
etc.
The file would be sourced in the **end** of `.zshrc`.

#### `~/.zsh-init.local`
If the `~/.zsh-init.local` file exists, it will be automatically sourced
before all the other [shell related files](shell).
The file would be sourced in the **beginning** of `.zshrc`.

#### `~/.zpreztorc.local`
If the `~/.zpreztorc.local` file exists, it will be automatically sourced
in the end of `.zpreztorc` to allow modifying its values, for example:

```zsh
# override theme
zstyle ':prezto:module:prompt' theme 'worktheme'

# add another module to the pmodules
zstyle -a ':prezto:load' pmodule pmodules
pmodules=(work-pmodule "${pmodules[@]}")
zstyle ':prezto:load' pmodule \
  'work-pmodule' \
  "${pmodules[@]}"
unset pmodules
```

#### `~/.zfunc`
This directory is automatically added to the zsh `fpath`, which allows putting local
specific zsh functions there: completions or other autoloaded stuff.

#### `~/.gitconfig.local`
If the `~/.gitconfig.local` file exists, it will be automatically
included after the configurations from [`~/.gitconfig`](git/gitconfig), thus, allowing
its content to overwrite or add to the existing `git` configurations.

**Note:** Use `~/.gitconfig.local` to store sensitive information such
as the `git` user credentials, or overrides, for example:

```
# ~/.gitconfig.local
[includeIf "gitdir:~/work"]
    path = ~/work/gitconfig

# ~/work/gitconfig
[user]
  email = workemail@example.com
  name = Work Name
```

## License
The code is available under the [MIT license](LICENSE).

## Credits
This repo was based on https://github.com/nicksp/dotfiles

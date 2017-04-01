# stek29's Dotfiles

This is a collection of dotfiles and scripts I use for customizing macOS to my liking and setting up the software development tools I use on a day-to-day basis. They should be cloned to your home directory so that the path is `~/dotfiles/`.  The included `setup.sh` script creates symlinks from your home directory to the files which are located in `~/dotfiles/`.

The setup script is smart enough to back up your existing dotfiles into a `~/dotfiles_old/` directory if you already have any dotfiles of the same name as the dotfile symlinks being created in your home directory.

I also prefer `zsh` as my shell of choice. As such, the setup script will also clone the `oh-my-zsh` repository from GitHub. It then checks to see if `zsh` is installed. If `zsh` is installed, and it is not already configured as the default shell, the setup script will execute a `chsh -s $(which zsh)` command. This changes the default shell to zsh, and takes effect as soon as a new zsh is spawned or on next login.

So, to recap, the install script will:

- back up any existing dotfiles in your home directory to `~/dotfiles_old/`
- create symlinks to the dotfiles in `~/dotfiles/` in your home directory
- clone the `oh-my-zsh` repository from GitHub (for use with `zsh`)
- clone themes and extenstions from GitHub (for oh-my-zsh)
- check to see if `zsh` is installed, if it isn't, try to install it
- if zsh is installed, run a `chsh -s` to set it as the default shell
- install Vundle and update all packages for it

## Features

- Git aliases
- zsh aliases
- [Install script](setup.sh)

## Installation

```sh
$ git clone --recursive https://github.com/stek29/dotfiles.git ~/dotfiles
$ cd ~/dotfiles
$ chmod +x setup.sh
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

#### `~/.zsh.theme`
If the `~/.zsh.local` file exists, it will be automatically sourced
before all the other [shell related files](shell) and oh-my-zsh, 
thus, allowing its content to modify oh-my-zsh settings.
If the file doesn't exist, `ZSH_THEME` would be set
to [pure](https://github.com/sindresorhus/pure)
The file would be sourced in the **beginning** of `.zshrc`.

#### `~/.gitconfig.local`

If the `~/.gitconfig.local` file exists, it will be automatically
included after the configurations from [`~/.gitconfig`](git/gitconfig), thus, allowing
its content to overwrite or add to the existing `git` configurations.

**Note:** Use `~/.gitconfig.local` to store sensitive information such
as the `git` user credentials.

## License

The code is available under the [MIT license](LICENSE).

<p align="center">
    <img src="img/polyglot_mascot.png" alt="Polyglot mascot">
</p>

[![License](img/mit_license.svg)](https://opensource.org/licenses/MIT)
[![GitHub tag](https://img.shields.io/github/tag/agkozak/polyglot.svg)](https://GitHub.com/agkozak/polyglot/tags/)
[![GitHub Stars](https://img.shields.io/github/stars/agkozak/polyglot.svg)](https://github.com/agkozak/agkozak-zsh-theme/stargazers)

# Polyglot Prompt

The **Polyglot Prompt** is a dynamic prompt for `zsh`, `bash`, `ksh93`, `mksh`, `pdksh`, `oksh`, `dash`, `yash`, `busybox ash`, and `osh` that uses basic ASCII symbols (and color, when possible) to show:

* the username
* whether a session is local or remote over SSH
* an abbreviated path
* the Git branch and status
* the exit status of the last command, if it was not zero
* any virtual environment created with `virtualenv`, `venv`, `pipenv`, `poetry`, or `conda`

![Polyglot Prompt demo](img/demo.gif)

*Note: There is also support for color in `pdksh`, `oksh`, and `osh`.*

## Table of Contents

- [Basics](#basics)
- [Installation](#installation)
- [Local and Remote Sessions](#local-and-remote-sessions)
- [Abbreviated Paths](#abbreviated-paths)
- [Git Branch and Status](#git-branch-and-status)
    + [`POLYGLOT_SHOW_UNTRACKED`](#polyglot_show_untracked)
- [Exit Status](#exit-status)
- [Virtual Environments](#virtual-environments)
- [Kubernetes Integration](#kubernetes-integration)
- [Colors in `pdksh`](#colors-in-pdksh)
- [Enabling `vi` editing mode in `zsh` and `bash`](#enabling-vi-editing-mode-in-zsh-and-bash)

## Basics

The central functions of the prompt are the same in all supported shells:

![Polyglot working in several shells](img/polyglot-with-several-shells.png)

Additionally, in `zsh` and in `bash` v4.3 and higher, the Polyglot Prompt indicates `vi` insert mode with a `+`, and command mode with a `:`, at the beginning of the prompt:

![`zsh` line editing](img/zsh-line-editing.png)

[See below](#enabling-vi-editing-mode-in-zsh-and-bash) for instructions on how to enable `vi` mode in your shell.

## Installation

The Polyglot Prompt uses one script (`polyglot.sh`) that can be sourced from the `rc` file (`.zshrc`, `.bashrc`, `.kshrc`, `.shrc`, `.mkshrc`, `.yashrc`, or `.config/oil/oshrc`) of any supported shell:

    . /path/to/polyglot.sh

Although no framework is required, a shim (`polyglot.plugin.zsh`) is provided to help with certain `zsh` frameworks.

## Local and Remote Sessions

When a session is local, only the username is shown; when it is remote over SSH (or `mosh`), the hostname is also shown:

![Local and remote sessions](img/local-and-remote-sessions.png)

*Note: It is exceedingly difficult to determine with accuracy whether a superuser is connected over SSH or not. In the interests of providing useful and not misleading information, this prompt always displays both username and hostname for a superuser in reverse video.*

## Abbreviated Paths

In all shells, by default the Polyglot Prompt emulates the behavior that `bash` uses when `PROMPT_DIRTRIM` is set to `2`: a tilde (`~`) is prepended if the working directory is under the user's home directory, and then if more than two directory elements need to be shown, only the last two are displayed, along with an ellipsis, so that

    /home/pi/src/neovim/config

is displayed as

![~/.../neovim/config](img/abbreviated_paths_1.png)

whereas

    /usr/src/sense-hat/examples

is displayed as

![.../sense-hat/examples](img/abbreviated_paths_2.png)

that is, without a tilde.

If you would like to display a different number of directory elements in your Polyglot Prompt, set the environment variable `$POLYGLOT_PROMPT_DIRTRIM` in an *rc* file thus:

    POLYGLOT_PROMPT_DIRTRIM=4     # Or whatever number you like

![POLYGLOT_PROMPT_DIRTRIM examples](img/POLYGLOT_PROMPT_DIRTRIM_examples.png)

Setting `POLYGLOT_PROMPT_DIRTRIM=0` disables path abbreviation, although `$HOME` will still be displayed as `~`.

## Git Branch and Status

If the current directory contains a Git repository, the Polyglot Prompt displays the name of the working branch, along with some symbols to show changes to its status:

![Git examples](img/git-examples.png)

Git Status | Symbol
--- | ---
Diverged | &\*
Behind | &
Ahead | \*
New file(s) | +
Deleted | x
Modified | !
Renamed | >
Untracked | ?

### `POLYGLOT_SHOW_UNTRACKED`

If you are working on an extremely large Git repository, such as an operating system kernel, calculating the Git status can be very slow. If you need to, you may set `POLYGLOT_SHOW_UNTRACKED=0`, which will cause the Polyglot Prompt to ignore the Git status for untracked files. This will have the effect of speeding up the display of the prompt considerably.

## Exit Status

If the exit status of the most recently executed command is other than zero (zero indicating success), the exit status will be displayed to the left of the prompt:

![Exit status displayed in `zsh`, `bash`, and `ksh`](img/exit-status.png)

## Virtual Environments

The Polyglot Prompt will display any active virtual environment created with `virtualenv`, `venv`, `pipenv`, `poetry`, or `conda` at the beginning of the prompt:

![Virtual environments](img/venv.png)

## Kubernetes Integration

If you are using the Polyglot Prompt with `bash` or `zsh`, you may add the Kubernetes context and namespace to your prompt with the add-on package [polyglot-kube-ps1](https://github.com/agkozak/polyglot-kube-ps1).

## Colors in `pdksh`

`pdksh` supports the use of color in prompts by allowing the programmer to choose a non-printing character and to use it to delimit color escape sequences. In practice, however, there is no one non-printing character that will work perfectly for all operating systems and terminals. The Polyglot Prompt defaults to `\021` for NetBSD and OpenBSD and to `\016` for everything else. If you want to try using your own non-printing character, you can specify it with the environment variable `POLYGLOT_NP`:

    POLYGLOT_NP="\016"  # Set this variable to any value you like

If all else fails, you can set `POLYGLOT_PDKSH_COLORS=0` to disable color entirely in `pdksh`.

## Enabling `vi` editing mode in `zsh` and `bash`

The Polyglot Prompt does not enable `vi` editing mode for you. In `zsh`, you may add

    bindkey -v

to your `.zshrc`; for `bash`, either put

    set-editing-mode vi

in your `.inputrc` or

    set -o vi

in your `.bashrc`.

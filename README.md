# `agkozak-git-prompt`
![screenshot](https://github.com/agkozak/agkozak-git-prompt/raw/master/img/agkozak-git-prompt.jpg)


`agkozak-git-prompt` is a dynamic color prompt for `zsh`, `bash`, `ksh`, `mksh`, and `dash` that displays the current Git branch and status of the working directory. It uses basic ASCII symbols to do so, not Unicode glyphs, so it works with more fonts. In `zsh` it has the added features of altering the appearance of the prompt when in vi command mode and of displaying exit codes in the right prompt.

The symbols that `agkozak-git-prompt` uses to represent Git status are as follows:

Git Status | Symbol
--- | ---
Modified | !
Deleted | x
Untracked | ?
New file(s) | +
Ahead | \*
Renamed | >

`agkozak-git-prompt` can be used without any shell framework and can be loaded thus:

     . /path/to/agkozak-git-prompt/agkozak-git-prompt.sh

If you do use a framework, consult its documentation to see how you can load `agkozak-git-prompt`. For `zsh`, I use [zplugin](https://github.com/zdharma/zplugin), so my `.zshrc` has the line

    zplugin load agkozak/agkozak-git-prompt


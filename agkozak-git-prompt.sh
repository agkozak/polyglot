#              _                 _
#   __ _  __ _| | _____ ______ _| | __
#  / _` |/ _` | |/ / _ \_  / _` | |/ /
# | (_| | (_| |   < (_) / / (_| |   <
#  \__,_|\__, |_|\_\___/___\__,_|_|\_\
#        |___/
#
# agkozak Git Prompt
#
# A Dynamic color Git prompt for zsh, bash, ksh93, mksh, and dash
#
# Copyright (C) 2017 Alexandros Kozák
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
#
# https://github.com/agkozak/agkozak-git-prompt
#
# shellcheck disable=SC2148

# Display current branch (if any) followed by changes to branch (if any)
#
# $1 is a hack that allows ksh93 to display a ! in its prompt
#
# shellcheck disable=SC2120
_branch_status() {
  ref=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  case $? in        # See what the exit code is.
    0) ;;           # $ref contains the name of a checked-out branch.
    128) return ;;  # No Git repository here.
    # Otherwise, see if HEAD is in detached state.
    *) ref=$(git rev-parse --short HEAD 2> /dev/null) || return ;;
  esac
  printf ' (%s%s)' "${ref#refs/heads/}" "$(_branch_changes "$1")"
}

# Display symbols representing the current branch's status
#
# $1 is a hack that allows ksh93 to display a ! in its prompt
_branch_changes() {
  git_status=$(git status 2>&1)

  symbols=''

  case "$git_status" in
    *'renamed:'*) symbols=">${symbols}" ;;
  esac
  case "$git_status" in
    *'Your branch is ahead of'*) symbols="*${symbols}" ;;
  esac
  case "$git_status" in
    *'new file:'*) symbols="+${symbols}" ;;
  esac
  case "$git_status" in
    *'Untracked files'*) symbols="?${symbols}" ;;
  esac
  case "$git_status" in
    *'deleted:'*) symbols="x${symbols}" ;;
  esac
  case "$git_status" in
    *'modified:'*)
      if [ "$1" = 'ksh93' ]; then # In ksh93, a single `!` displays the command
        symbols="!!${symbols}"  # number, while two exclamation points are
      else                      # displayed as one.
        symbols="!${symbols}"
      fi
    ;;
  esac

  [ "$symbols" ] && printf '%s' " $symbols"
}

_has_colors() {
  test "$(tput colors)" -ge 8
}

# zsh
if [ -n "$ZSH_VERSION" ]; then
  setopt PROMPT_SUBST

  # vi-mode indicator
  #
  # Hat-tip to oh-my-zsh's vi-mode plugin, with which this prompt is compatible:
  # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/vi-mode

  # shellcheck disable=SC2034
  MODE_INDICATOR=':'  # Defined only so that it will not be overridden by
                      # oh-my-zsh's vi-mode plugin

  # Underscores are used in the new keymap's name to keep `dash` from choking on hyphens
  zle_keymap_select() {
    zle reset-prompt
    zle -R
  }

  zle -N zle_keymap_select
  zle -A zle_keymap_select zle-keymap-select

  # Redraw prompt when terminal size changes
  TRAPWINCH() {
    zle && zle -R
  }

  _zsh_vi_mode_indicator() {
    case "$KEYMAP" in
      vicmd)
        if whence -w colors > /dev/null 2>&1; then
          printf '%s' "%{$bg[cyan]$fg[black]%}:%{$reset_color%}"
        else
          printf '%s' ':'
        fi
        ;;
      *) printf '%s' '+' ;;
    esac
  }

  if _has_colors; then
    # Autoload zsh colors module if it hasn't been autoloaded already
    if ! whence -w colors > /dev/null 2>&1; then
      autoload -Uz colors
      colors
    fi

    # shellcheck disable=SC2154
    PS1='$(_zsh_vi_mode_indicator)%{$fg_bold[green]%}%n@%m%{$reset_color%} %{$fg_bold[blue]%}%(3~|.../%2~|%~)%{$reset_color%}%{$fg[yellow]%}$(_branch_status)%{$reset_color%} %# '

    # The right prompt will show the exit code if it is not zero.
    RPS1="%(?..%{$fg_bold[red]%}(%?%)%{$reset_color%})"

  else
    PS1='$(_zsh_vi_mode_indicator)%n@%m %(3~|.../%2~|%~)$(_branch_status) %# '
    # shellcheck disable=SC2034
    RPS1="%(?..(%?%))"
  fi

# bash
elif [ -n "$BASH_VERSION" ]; then
  PROMPT_DIRTRIM=2

  # vi command mode
  bind 'set show-mode-in-prompt'                # Since bash 4.3
  bind 'set vi-ins-mode-string "+"'             # Since bash 4.4
  if _has_colors; then
    bind 'set vi-cmd-mode-string "\e[30;46m:\e[00m"'           # Since bash 4.4
  else
    bind 'set vi-cmd-mode-string ":"'
  fi

  if _has_colors; then
    PS1="\[\e[01;32m\]\u@\h\[\e[00m\] \[\e[01;34m\]\w\[\e[m\]\[\e[0;33m\]\$(_branch_status)\[\e[m\] \\$ "
  else
    # shellcheck disable=SC2119,SC2155
    PS1="\u@\h \w$(_branch_status) \\$ "
  fi

# ksh93 and mksh
elif [ -n "$KSH_VERSION" ]; then
  _AGKOZAK_HOSTNAME=$(hostname)
  _AGKOZAK_HOSTNAME=${_AGKOZAK_HOSTNAME%?${_AGKOZAK_HOSTNAME#*.}}

  case "$KSH_VERSION" in
    *MIRBSD*)
      # For now, a color prompt is disabled for mksh, as that shell tends to
      # "wrap" incorrectly
      #
      # if _has_colors; then
        # shellcheck disable=SC2016
        # PS1=$(print '\e[01;32m$LOGNAME@$HOSTNAME\e[00m \e[01;34m$(echo $PWD | sed "s,^$HOME,~,")\e[0;33m$(_branch_status)\e[00m \$ ')
      # else
        PS1='$LOGNAME@$_AGKOZAK_HOSTNAME $(echo $PWD | sed "s,^$HOME,~,")$(_branch_status) \$ '
      # fi
      ;;
    *)
      if _has_colors; then
        # shellcheck disable=SC2039
        PS1=$'\E[32;1m$LOGNAME@$_AGKOZAK_HOSTNAME\E[0m \E[34;1m$(echo $PWD | sed "s,^$HOME,~,")\E[0m\E[33m$(_branch_status ksh93)\E[0m \$ '
      else
        PS1='$LOGNAME@$_AGKOZAK_HOSTNAME $(echo $PWD | sed "s,^$HOME,~,")$(_branch_status ksh93) \$ '
      fi
      ;;
  esac
# dash
elif [ "$(basename "$0")" = 'dash' ]; then
  _AGKOZAK_HOSTNAME=$(hostname)
  _AGKOZAK_HOSTNAME=${_AGKOZAK_HOSTNAME%?${_AGKOZAK_HOSTNAME#*.}}

  PS1='$LOGNAME@$_AGKOZAK_HOSTNAME $(echo $PWD | sed "s,^$HOME,~,")$(_branch_status) $ '

else
  echo 'agkozak-git-prompt does not support your shell.'
fi

# vim: foldmethod=marker tabstop=2 expandtab

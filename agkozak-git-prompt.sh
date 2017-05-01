#              _                 _
#   __ _  __ _| | _____ ______ _| | __
#  / _` |/ _` | |/ / _ \_  / _` | |/ /
# | (_| | (_| |   < (_) / / (_| |   <
#  \__,_|\__, |_|\_\___/___\__,_|_|\_\
#        |___/
#
# agkozak Git Prompt
#
# A dynamic color Git prompt for zsh, bash, ksh93, mksh, dash, and busybox sh
#
#
# Source this file from a relevant dotfile (e.g. .zshrc, .bashrc, .kshrc,
# .mkshrc, or .shrc) thus:
#
#   . /path/to/agkozak-git-prompt.sh
#
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

###########################################################
# Is the user connected via SSH?
# Returns:
#   boolean
###########################################################
_is_ssh() {
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    return 0
  else
    case "$EUID" in
      0)
        case $(ps -o comm= -p $PPID) in
          sshd|*/sshd) return 0 ;;
        esac
        ;;
      *) return 1 ;;
    esac
  fi
}

###########################################################
# Does the terminal support enough colors?
# Returns:
#   boolean
###########################################################
_has_colors() {
  [ "$(tput colors)" -ge 8 ]
}

###########################################################
# Display current branch name, followed by symbols
# representing changes to the working copy
# Arguments:
#   $1 if ksh93, escape ! as !!
###########################################################
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

###########################################################
# Display symbols representing changes to the working copy
# Arguments:
#   $1 if ksh93, escape ! as !!
###########################################################
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

###########################################################
# Emulation of bash's PROMPT_DIRTRIM for other shells
#
# In $PWD, substitute $HOME with ~; if the remainder of the
# $PWD has more than two directory elements to display,
# abbreviate it with '...', e.g.
#
#   ~/.../agkozak-git-prompt/img
###########################################################
_prompt_dirtrim() {
  first_two_dirs=$(echo "${PWD#$HOME}" | cut -d '/' -f1-3)
  last_two_dirs=$(echo "${PWD#$HOME}" | awk '{ for(i=length();i!=0;i--) x=(x substr($0,i,1)) }{print x;x=""}' | cut -d '/' -f-2 | awk '{ for(i=length();i!=0;i--) x=(x substr($0,i,1)) }{print x;x=""}')
  if [ "$last_two_dirs" = "$first_two_dirs" ] || [ "/$last_two_dirs" = "$first_two_dirs" ]; then
    case "$PWD" in
      $HOME*) printf '~%s\n' "${PWD#$HOME}" ;;
      *) printf '%s\n' "$PWD" ;;
    esac
  else
    #shellcheck disable=SC2088
    case "$PWD" in
      $HOME*) printf '~/.../%s\n' "$last_two_dirs" ;;
      *) printf '.../%s\n' "$last_two_dirs" ;;
    esac
  fi
}

###########################################################
# Tests to see if the current shell is busybox sh (ash)
# Returns:
#   boolean
###########################################################
_is_busybox() {
  if command -v readlink > /dev/null 2>&1; then
    case "$(exec 2> /dev/null; readlink "/proc/$$/exe")" in
      */busybox) return 0 ;;
      *) return 1 ;;
    esac
  else
    return 1
  fi
}

#####################################################################
# zsh
#####################################################################
if [ -n "$ZSH_VERSION" ]; then
  setopt PROMPT_SUBST

  ###########################################################
  # Runs right before the prompts is displayed
  #
  # 1) Imitates bash's PROMPT_DIRTRIM=2 behavior
  # 2) Calculates working branch and working copy status
  ###########################################################
  precmd() {
    # shellcheck disable=SC2128,SC2088
    case "$PWD" in
      $HOME*)
        psvar[2]=$(print -P "%(4~|.../%2~|%~)")
        case "$psvar[2]" in
          '...'*) psvar[2]=$(printf '~/%s' "$psvar[2]")
        esac
        ;;
      *) psvar[2]=$(print -P "%(3~|.../%2~|%~)") ;;
    esac
    psvar[3]=$(_branch_status)
  }

  ###########################################################
  # When the user enters vi command mode, the % or # in the
  # prompt changes into a colon
  ###########################################################
  _zsh_vi_mode_indicator() {
    case "$KEYMAP" in
      vicmd) printf '%s' ':' ;;
      *) printf '%s' '%#' ;;
    esac
  }

  ###########################################################
  # Redraw the prompt when the vi mode changes
  #
  # Underscores are used in this function's name to keep
  # dash from choking on hyphens
  ###########################################################
  zle_keymap_select() {
    zle reset-prompt
    zle -R
  }

  zle -N zle_keymap_select
  zle -A zle_keymap_select zle-keymap-select

  ###########################################################
  # Redraw prompt when terminal size changes
  ###########################################################
  TRAPWINCH() {
    zle && zle -R
  }

  if _is_ssh; then
    psvar[1]=$(print -P '@%m')
  else
    #shellcheck disable=SC2034
    psvar[1]=''
  fi

  if _has_colors; then
    # Autoload zsh colors module if it hasn't been autoloaded already
    if ! whence -w colors > /dev/null 2>&1; then
      autoload -Uz colors
      colors
    fi

    # shellcheck disable=SC2154
    PS1='%{$fg_bold[green]%}%n%1v%{$reset_color%} %{$fg_bold[blue]%}%2v%{$reset_color%}%{$fg[yellow]%}%3v%{$reset_color%} $(_zsh_vi_mode_indicator) '

    # The right prompt will show the exit code if it is not zero.
    RPS1="%(?..%{$fg_bold[red]%}(%?%)%{$reset_color%})"

  else
    PS1='%n%1v %2v%3v $(_zsh_vi_mode_indicator) '
    # shellcheck disable=SC2034
    RPS1="%(?..(%?%))"
  fi

#####################################################################
# bash
#####################################################################
elif [ -n "$BASH_VERSION" ]; then
  PROMPT_DIRTRIM=2

  if _is_ssh; then
    _AGKOZAK_HOSTNAME_STRING='@\h'
  else
    _AGKOZAK_HOSTNAME_STRING=''
  fi

  # vi command mode
  bind 'set show-mode-in-prompt'                # Since bash 4.3
  bind 'set vi-ins-mode-string "+"'             # Since bash 4.4
  if _has_colors; then
    bind 'set vi-cmd-mode-string "\e[30;46m:\e[00m"'           # Since bash 4.4
  else
    bind 'set vi-cmd-mode-string ":"'
  fi

  if _has_colors; then
    PS1="\[\e[01;32m\]\u$_AGKOZAK_HOSTNAME_STRING\[\e[00m\] \[\e[01;34m\]\w\[\e[m\]\[\e[0;33m\]\$(_branch_status)\[\e[m\] \\$ "
  else
    # shellcheck disable=SC2119,SC2155
    PS1="\u$_AGKOZAK_HOSTNAME_STRING \w$(_branch_status bash) \\$ "
  fi

#####################################################################
# ksh93, mksh, pdksh, dash, busybox sh
#####################################################################
elif [ -n "$KSH_VERSION" ] || [ "$0" = 'dash' ] || _is_busybox; then
  if _is_ssh; then
    _AGKOZAK_HOSTNAME_STRING=$(hostname)
    _AGKOZAK_HOSTNAME_STRING="@${_AGKOZAK_HOSTNAME_STRING%?${_AGKOZAK_HOSTNAME_STRING#*.}}"
  else
    _AGKOZAK_HOSTNAME_STRING=''
  fi

  PS1='$LOGNAME$_AGKOZAK_HOSTNAME_STRING $(_prompt_dirtrim)$(_branch_status) $ '

  case "$KSH_VERSION" in
    # mksh handles color badly, so I'm avoiding it for now
    *MIRBSD*|*'PD KSH'*) ;;
    # ksh93 handles color well, but requires escaping ! as !!
    *)
      if _has_colors; then
        # shellcheck disable=SC2039
        PS1=$'\E[32;1m$LOGNAME$_AGKOZAK_HOSTNAME_STRING\E[0m \E[34;1m$(_prompt_dirtrim)\E[0m\E[33m$(_branch_status ksh93)\E[0m \$ '
      else
        PS1='$LOGNAME$_AGKOZAK_HOSTNAME_STRING $(_prompt_dirtrim)$(_branch_status ksh93) \$ '
      fi
      ;;
  esac

else
  printf '%s\n' 'agkozak-git-prompt does not support your shell.'
fi

# vim: foldmethod=marker tabstop=2 expandtab

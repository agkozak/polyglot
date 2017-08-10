#              _             _       _
#  _ __   ___ | |_   _  __ _| | ___ | |_
# | '_ \ / _ \| | | | |/ _` | |/ _ \| __|
# | |_) | (_) | | |_| | (_| | | (_) | |_
# | .__/ \___/|_|\__, |\__, |_|\___/ \__|
# |_|            |___/ |___/
#
# Polyglot Prompt
#
# A dynamic color Git prompt for zsh, bash, ksh93, mksh, pdksh, dash, and
# busybox sh
#
#
# Source this file from a relevant dotfile (e.g. .zshrc, .bashrc, .kshrc,
# .mkshrc, or .shrc) thus:
#
#   . /path/to/polyglot.sh
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
# https://github.com/agkozak/polyglot
#

# shellcheck disable=SC2148

[ -z "$POLYGLOT_PROMPT_DIRTRIM" ] && POLYGLOT_PROMPT_DIRTRIM=2

############################################################
# Display non-zero exit status
# Arguments:
#   $1 exit status of last command (always $?)
############################################################
_polyglot_exit_status() {
  case $1 in
    0) return ;;
    *) printf '(%d) ' "$1" ;;
  esac
}

###########################################################
# Is the user connected via SSH?
###########################################################
_polyglot_is_ssh() {
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    return 0
  else
    case $EUID in
      0)
        case $(ps -o comm= -p $PPID) in
          sshd|*/sshd) return 0 ;;
          *) return 1 ;;
        esac
        ;;
      *) return 1 ;;
    esac
  fi
}

###########################################################
# Does the terminal support enough colors?
###########################################################
_polyglot_has_colors() {
  if [ "$_POLYGLOT_HAS_COLORS" ]; then
    return 0
  elif [ "$(tput colors)" -ge 8 ]; then
    _POLYGLOT_HAS_COLORS=1
    return 0
  else
    return 1
  fi
}

###########################################################
# Display current branch name, followed by symbols
# representing changes to the working copy
# Arguments:
#   $1 if ksh93, escape ! as !!
###########################################################
# shellcheck disable=SC2120
_polyglot_branch_status() {
  [ -n "$ZSH_VERSION" ] && setopt NO_WARN_CREATE_GLOBAL
  ref=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  case $? in        # See what the exit code is.
    0) ;;           # $ref contains the name of a checked-out branch.
    128) return ;;  # No Git repository here.
    # Otherwise, see if HEAD is in detached state.
    *) ref=$(git rev-parse --short HEAD 2> /dev/null) || return ;;
  esac
  printf ' (%s%s)' "${ref#refs/heads/}" "$(_polyglot_branch_changes "$1")"
}

###########################################################
# Display symbols representing changes to the working copy
# Arguments:
#   $1 if ksh93, escape ! as !!
###########################################################
_polyglot_branch_changes() {
  [ -n "$ZSH_VERSION" ] && setopt NO_WARN_CREATE_GLOBAL

  git_status=$(LC_ALL=C git status 2>&1)

  symbols=''

  case $git_status in
    *'renamed:'*) symbols=">${symbols}" ;;
  esac
  case $git_status in
    *'Your branch is ahead of'*) symbols="*${symbols}" ;;
  esac
  case $git_status in
    *'new file:'*) symbols="+${symbols}" ;;
  esac
  case $git_status in
    *'Untracked files'*) symbols="?${symbols}" ;;
  esac
  case $git_status in
    *'deleted:'*) symbols="x${symbols}" ;;
  esac
  case $git_status in
    *'modified:'*)
      if [ "$1" = 'ksh93' ]; then # In ksh93, a single `!` displays the command
        symbols="!!${symbols}"    # number, while two exclamation points are
      else                        # displayed as one exclamation point.
        symbols="!${symbols}"
      fi
    ;;
  esac

  [ "$symbols" ] && printf ' %s' "$symbols"
}

###########################################################
# Tests to see if the current shell is busybox sh (ash)
###########################################################
_polyglot_is_busybox() {
  if command -v readlink > /dev/null 2>&1; then
    case $(exec 2> /dev/null; readlink "/proc/$$/exe") in
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

  ############################################################
  # Emulation of bash's PROMPT_DIRTRIM for zsh
  #
  # In $PWD, substitute $HOME with ~; if the remainder of the
  # $PWD has more than two directory elements to display,
  # abbreviate it with '...', e.g.
  #
  #   $HOME/dotfiles/polyglot/img
  #
  # will be displayed as
  #
  #   ~/.../polyglot/img
  #
  # Arguments
  #  $1 Number of directory elements to display
  ############################################################
  _polyglot_zsh_prompt_dirtrim() {
    local abbreviated_path
    [[ $1 -ge 1 ]] || set 2
    case $PWD in
      $HOME) print -n '~' ;;
      $HOME*)
        abbreviated_path=$(print -Pn "%($(($1 + 2))~|.../%${1}~|%~)")
        # shellcheck disable=SC2088
        case $abbreviated_path in
          '.../'*) abbreviated_path=$(printf '~/%s' "$abbreviated_path") ;;
        esac
        ;;
      *)
        abbreviated_path=$(print -Pn "%($(($1 + 1))~|.../%${1}~|%~)")
        ;;
    esac
    print -n "$abbreviated_path"
  }

  ###########################################################
  # Runs right before the prompt is displayed
  #
  # 1) Imitates bash's PROMPT_DIRTRIM behavior
  # 2) Calculates working branch and working copy status
  ###########################################################
  precmd() {
    psvar[2]=$(_polyglot_zsh_prompt_dirtrim $POLYGLOT_PROMPT_DIRTRIM)
    # shellcheck disable=SC2119
    psvar[3]=$(_polyglot_branch_status)
  }

  ###########################################################
  # When the user enters vi command mode, the % or # in the
  # prompt changes into a colon
  ###########################################################
  _polyglot_zsh_vi_mode_indicator() {
    case $KEYMAP in
      vicmd) print -n ':' ;;
      *) print -n '%#' ;;
    esac
  }

  ###########################################################
  # Redraw the prompt when the vi mode changes
  #
  # Underscores are used in this function's name to keep
  # dash from choking on hyphens
  ###########################################################
  _polyglot_zle_keymap_select() {
    zle reset-prompt
    zle -R
  }

  zle -N _polyglot_zle_keymap_select
  zle -A _polyglot_zle_keymap_select zle-keymap-select

  ###########################################################
  # Redraw prompt when terminal size changes
  ###########################################################
  TRAPWINCH() {
    zle && zle -R
  }

  if _polyglot_is_ssh; then
    psvar[1]=$(print -P '@%m')
  else
    # shellcheck disable=SC2034
    psvar[1]=''
  fi

  if _polyglot_has_colors; then
    # Autoload zsh colors module if it hasn't been autoloaded already
    if ! whence -w colors > /dev/null 2>&1; then
      autoload -Uz colors
      colors
    fi

    # shellcheck disable=SC2154
    PS1='%{$fg_bold[green]%}%n%1v%{$reset_color%} %{$fg_bold[blue]%}%2v%{$reset_color%}%{$fg[yellow]%}%3v%{$reset_color%} $(_polyglot_zsh_vi_mode_indicator) '

    # The right prompt will show the exit code if it is not zero.
    RPS1="%(?..%{$fg_bold[red]%}(%?%)%{$reset_color%})"

  else
    PS1='%n%1v %2v%3v $(_polyglot_zsh_vi_mode_indicator) '
    # shellcheck disable=SC2034
    RPS1="%(?..(%?%))"
  fi

#####################################################################
# bash
#####################################################################
elif [ -n "$BASH_VERSION" ]; then

  _polyglot_prompt_command() {
    PROMPT_DIRTRIM=$POLYGLOT_PROMPT_DIRTRIM
    if _polyglot_has_colors; then
      PS1="\[\e[01;31m\]\$(_polyglot_exit_status \$?)\[\e[00m\]\[\e[01;32m\]\u$_POLYGLOT_HOSTNAME_STRING\[\e[00m\] \[\e[01;34m\]\w\[\e[m\e[0;33m\]\$(_polyglot_branch_status)\[\e[00m\] \\$ "
    else
      PS1="\$(_polyglot_exit_status \$?)\u$_POLYGLOT_HOSTNAME_STRING \w\$(_polyglot_branch_status) \\$ "
    fi
  }

  if _polyglot_is_ssh; then
    _POLYGLOT_HOSTNAME_STRING='@\h'
  else
    _POLYGLOT_HOSTNAME_STRING=''
  fi

  PROMPT_COMMAND='_polyglot_prompt_command'

  # vi command mode
  bind 'set show-mode-in-prompt'                      # Since bash 4.3
  bind 'set vi-ins-mode-string "+"'
  bind 'set vi-cmd-mode-string ":"'

#####################################################################
# ksh93, mksh, pdksh, dash, busybox sh
#####################################################################
elif [ -n "$KSH_VERSION" ] || [ "$0" = 'dash' ] || _polyglot_is_busybox; then

  ############################################################
  # Emulation of bash's PROMPT_DIRTRIM for other shells
  #
  # In $PWD, substitute $HOME with ~; if the remainder of the
  # $PWD has more than two directory elements to display,
  # abbreviate it with '...', e.g.
  #
  #   $HOME/dotfiles/polyglot/img
  #
  # will be displayed as
  #
  #   ~/.../polyglot/img
  #
  # Arguments
  #  $1 Number of directory elements to display
  ############################################################
  _polyglot_prompt_dirtrim() {
    [ "$1" -lt 1 ] && set 2 # $POLYGLOT_PROMPT_DIRTRIM should not be less than 1
    dir_count=$(echo "${PWD#$HOME}" | awk -F/ '{c += NF - 1} END {print c}')
    if [ "$dir_count" -le "$1" ]; then
        # shellcheck disable=SC2088
        case $PWD in
          "$HOME"*) printf '~%s' "${PWD#$HOME}" ;;
          *) printf '%s' "$PWD" ;;
        esac
    else
      last_two_dirs=$(echo "${PWD#$HOME}" \
        | awk '{ for(i=length();i!=0;i--) x=(x substr($0,i,1))  }{print x;x=""}' \
        | cut -d '/' -f-"$1" \
        | awk '{ for(i=length();i!=0;i--) x=(x substr($0,i,1))  }{print x;x=""}')
        # shellcheck disable=SC2088
        case $PWD in
          "$HOME"*) printf '~/.../%s' "$last_two_dirs" ;;
          *) printf '.../%s' "$last_two_dirs" ;;
        esac
    fi
  }

  if _polyglot_is_ssh; then
    _POLYGLOT_HOSTNAME_STRING=$(hostname)
    _POLYGLOT_HOSTNAME_STRING="@${_POLYGLOT_HOSTNAME_STRING%?${_POLYGLOT_HOSTNAME_STRING#*.}}"
  else
    _POLYGLOT_HOSTNAME_STRING=''
  fi

  PS1='$(_polyglot_exit_status $?)$LOGNAME$_POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim $POLYGLOT_PROMPT_DIRTRIM)$(_polyglot_branch_status) $ '

  if [ -n "$KSH_VERSION" ]; then
    case $KSH_VERSION in
      # mksh handles color badly, so I'm avoiding it for now
      *MIRBSD*|*'PD KSH'*) ;;
      # ksh93 handles color well, but requires escaping ! as !!
      *)
        if _polyglot_has_colors; then
          PS1=$'\E[31;1m$(_polyglot_exit_status $?)\E[0m\E[32;1m$LOGNAME$_POLYGLOT_HOSTNAME_STRING\E[0m \E[34;1m$(_polyglot_prompt_dirtrim $POLYGLOT_PROMPT_DIRTRIM)\E[0m\E[33m$(_polyglot_branch_status ksh93)\E[0m \$ '
        else
          PS1='$(_polyglot_exit_status $?)$LOGNAME$_POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim $POLYGLOT_PROMPT_DIRTRIM)$(_polyglot_branch_status ksh93) \$ '
        fi
        ;;
    esac
  fi

else
  printf '%s\n' 'Polyglot Prompt does not support your shell.'
fi

# vim: foldmethod=marker tabstop=2 expandtab

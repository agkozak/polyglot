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
# Copyright 2017 Alexandros Kozak
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
# https://github.com/agkozak/polyglot
#

# shellcheck disable=SC2148

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
  if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
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
  [ "$(tput colors)" -ge 8 ]
}

###########################################################
# Display current branch name, followed by symbols
# representing changes to the working copy
###########################################################
# shellcheck disable=SC2120
_polyglot_branch_status() {
  [ -n "$ZSH_VERSION" ] && setopt NO_WARN_CREATE_GLOBAL
  POLYGLOT_REF=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  case $? in        # See what the exit code is.
    0) ;;           # $ref contains the name of a checked-out branch.
    128) return ;;  # No Git repository here.
    # Otherwise, see if HEAD is in detached state.
    *) POLYGLOT_REF=$(git rev-parse --short HEAD 2> /dev/null) || return ;;
  esac
  printf ' (%s%s)' "${POLYGLOT_REF#refs/heads/}" "$(_polyglot_branch_changes)"
}

###########################################################
# Display symbols representing changes to the working copy
###########################################################
_polyglot_branch_changes() {
  [ -n "$ZSH_VERSION" ] && setopt NO_WARN_CREATE_GLOBAL

  POLYGLOT_GIT_STATUS=$(LC_ALL=C git status 2>&1)

  POLYGLOT_SYMBOLS=''

  case $POLYGLOT_GIT_STATUS in
    *'renamed:'*) POLYGLOT_SYMBOLS=">${POLYGLOT_SYMBOLS}" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'Your branch is ahead of'*) POLYGLOT_SYMBOLS="*${POLYGLOT_SYMBOLS}" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'new file:'*) POLYGLOT_SYMBOLS="+${POLYGLOT_SYMBOLS}" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'Untracked files'*) POLYGLOT_SYMBOLS="?${POLYGLOT_SYMBOLS}" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'deleted:'*) POLYGLOT_SYMBOLS="x${POLYGLOT_SYMBOLS}" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'modified:'*) POLYGLOT_SYMBOLS="!${POLYGLOT_SYMBOLS}" ;;
  esac

  [ "$POLYGLOT_SYMBOLS" ] && printf ' %s' "$POLYGLOT_SYMBOLS"
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
  # Arguments:
  #   $1 Number of directory elements to display
  ############################################################
  _polyglot_zsh_prompt_dirtrim() {
    [ "$1" -gt 0 ] || set 2
    local abbreviated_path
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
    psvar[2]=$(_polyglot_zsh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")
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

  ###########################################################
  # Create the bash $PROMPT_COMMAND
  #
  # Arguments:
  #   $1 Number of directory elements to display
  ###########################################################
  _polyglot_prompt_command() {
    [ -n "$1" ] && [ "$1" -gt 0 ] && PROMPT_DIRTRIM=$1 || PROMPT_DIRTRIM=2

    if _polyglot_has_colors; then
      PS1="\\[\\e[01;31m\\]\$(_polyglot_exit_status \$?)\\[\\e[00m\\]\\[\\e[01;32m\\]\\u$POLYGLOT_HOSTNAME_STRING\\[\\e[00m\\] \\[\\e[01;34m\\]\\w\\[\\e[m\\e[0;33m\\]\$(_polyglot_branch_status)\\[\\e[00m\\] \\$ "
    else
      PS1="\$(_polyglot_exit_status \$?)\\u$POLYGLOT_HOSTNAME_STRING \\w\$(_polyglot_branch_status) \\$ "
    fi
  }

  if _polyglot_is_ssh; then
    POLYGLOT_HOSTNAME_STRING='@\h'
  else
    POLYGLOT_HOSTNAME_STRING=''
  fi

  PROMPT_COMMAND='_polyglot_prompt_command $POLYGLOT_PROMPT_DIRTRIM'

  # vi command mode
  bind 'set show-mode-in-prompt'                      # Since bash 4.3
  bind 'set vi-ins-mode-string "+"'
  bind 'set vi-cmd-mode-string ":"'

#####################################################################
# ksh93, mksh, pdksh, dash, busybox sh
#####################################################################
elif [ -n "$KSH_VERSION" ] || [ "$0" = 'dash' ] || _polyglot_is_busybox; then

  ############################################################
  # Use nawk on Solaris, system awk everywhere else
  #
  # Arguments:
  #   $@ awk arguments
  ############################################################
  case $(uname -a) in
    SunOS*) _polyglot_awk() { command nawk "$@"; } ;;
    *) _polyglot_awk() { command awk "$@"; } ;;
  esac

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
  # Arguments:
  #   $1 Number of directory elements to display
  ############################################################
  _polyglot_prompt_dirtrim() {
    #shellcheck disable=SC2015
    [ -n "$1" ] && [ "$1" -gt 0 ] || set 2

    POLYGLOT_DIR_COUNT=$(echo "${PWD#$HOME}" | awk -F/ '{c+=NF-1} END {print c}')
    if [ "$POLYGLOT_DIR_COUNT" -le "$1" ]; then
        # shellcheck disable=SC2088
        case $PWD in
          "$HOME"*) printf '~%s' "${PWD#$HOME}" ;;
          *) printf '%s' "$PWD" ;;
        esac
    else
      POLYGLOT_LAST_TWO_DIRS=$(echo "${PWD#$HOME}" \
      | _polyglot_awk -F/ -v prompt_dirtrim=$1 \
      '{for(i=NF-prompt_dirtrim+1;i<=NF;i++)printf "/%s",$i}')
        # shellcheck disable=SC2088
        case $PWD in
          "$HOME"*) printf '~/...%s' "$POLYGLOT_LAST_TWO_DIRS" ;;
          *) printf '...%s' "$POLYGLOT_LAST_TWO_DIRS" ;;
        esac
    fi
  }

  if _polyglot_is_ssh; then
    POLYGLOT_HOSTNAME_STRING=$(hostname)
    POLYGLOT_HOSTNAME_STRING="@${POLYGLOT_HOSTNAME_STRING%?${POLYGLOT_HOSTNAME_STRING#*.}}"
  else
    POLYGLOT_HOSTNAME_STRING=''
  fi

  PS1='$(_polyglot_exit_status $?)$LOGNAME$POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim $POLYGLOT_PROMPT_DIRTRIM)$(_polyglot_branch_status) $ '

  if [ -n "$KSH_VERSION" ]; then
    case $KSH_VERSION in
      # mksh handles color badly, so I'm avoiding it for now
      *MIRBSD*|*'PD KSH'*) ;;
      # ksh93 handles color well, but requires escaping ! as !!
      *)
        if _polyglot_has_colors; then
          PS1=$'\E[31;1m$(_polyglot_exit_status $?)\E[0m\E[32;1m$LOGNAME$POLYGLOT_HOSTNAME_STRING\E[0m \E[34;1m$(_polyglot_prompt_dirtrim $POLYGLOT_PROMPT_DIRTRIM)\E[0m\E[33m$(polyglot_branch_status=$(_polyglot_branch_status); echo "${polyglot_branch_status//\!/\!!}")\E[0m \$ '
        else
          # shellcheck disable=SC2154
          PS1='$(_polyglot_exit_status $?)$LOGNAME$POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim $POLYGLOT_PROMPT_DIRTRIM)$(polyglot_branch_status=$(_polyglot_branch_status); echo "${polyglot_branch_status//\!/\!!}") \$ '
        fi
        ;;
    esac
  fi

else
  printf '%s\n' 'Polyglot Prompt does not support your shell.' >&2
fi

# Clean up environment
unset -f _polyglot_is_ssh _polyglot_is_busybox

# vim: foldmethod=marker tabstop=2 expandtab

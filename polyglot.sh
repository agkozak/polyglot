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
# busybox ash
#
#
# Source this file from a relevant dotfile (e.g. .zshrc, .bashrc, .shrc, .kshrc,
# or .mkshrc) thus:
#
#   . /path/to/polyglot.sh
#
# Set $POLYGLOT_PROMPT_DIRTRIM to the number of directory elements you would like
# to have displayed in your prompt (the default is 2). For example,
#
# POLYGLOT_PROMPT_DIRTRIM=3
#
# results in
#
#   ~/foo/bar/bat/quux
#
# displaying as
#
#   ~/.../bar/bat/quux
#
#
# Copyright 2017-2018 Alexandros Kozak
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
#
# https://github.com/agkozak/polyglot
#

# shellcheck disable=SC1117,SC2016,SC2034,SC2088,SC2148,SC2154

############################################################
# Display non-zero exit status
#
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
  [ -n "${SSH_CONNECTION-}${SSH_CLIENT-}${SSH_TTY-}" ]
}

###########################################################
# Is the user a superuser?
###########################################################
_polyglot_is_superuser() {
  [ ${EUID:-$(id -u)} -eq 0 ]
}

###########################################################
# Does the terminal support enough colors?
###########################################################
_polyglot_has_colors() {
  case $TERM in
    *-256color) POLYGLOT_TERM_COLORS=256 ;;
    vt100|dumb) POLYGLOT_TERM_COLORS=-1 ;;
    *)
      case $(uname -s) in
        FreeBSD) POLYGLOT_TERM_COLORS=$(tput Co) ;;
        *) POLYGLOT_TERM_COLORS=$(tput colors) ;;
      esac
      ;;
  esac
  if [ "${POLYGLOT_TERM_COLORS:-0}" -ge 8 ]; then
    unset POLYGLOT_TERM_COLORS
    return 0
  else
    unset POLYGLOT_TERM_COLORS
    return 1
  fi
}

###########################################################
# Display current branch name, followed by symbols
# representing changes to the working copy
#
# Arguments:
#   $1  If ksh, escape ! as !!
###########################################################
# shellcheck disable=SC2120
_polyglot_branch_status() {
  [ -n "$ZSH_VERSION" ] && \
    setopt LOCAL_OPTIONS NO_WARN_CREATE_GLOBAL NO_WARN_NESTED_VAR > /dev/null 2>&1
  POLYGLOT_REF=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  case $? in        # See what the exit code is.
    0) ;;           # $POLYGLOT_REF contains the name of a checked-out branch.
    128) return ;;  # No Git repository here.
    # Otherwise, see if HEAD is in a detached state.
    *) POLYGLOT_REF=$(git rev-parse --short HEAD 2> /dev/null) || return ;;
  esac

  if [ -n "$POLYGLOT_REF" ]; then
    printf ' (%s%s)' "${POLYGLOT_REF#refs/heads/}" "$(_polyglot_branch_changes "$1")"
  fi

  unset POLYGLOT_REF
}

###########################################################
# Display symbols representing changes to the working copy
#
# Arguments:
#   $1  If ksh, escape ! as !!
###########################################################
_polyglot_branch_changes() {
  [ -n "$ZSH_VERSION" ] && \
    setopt LOCAL_OPTIONS NO_WARN_CREATE_GLOBAL NO_WARN_NESTED_VAR > /dev/null 2>&1

  POLYGLOT_GIT_STATUS=$(LC_ALL=C git status 2>&1)

  POLYGLOT_SYMBOLS=''

  case $POLYGLOT_GIT_STATUS in
    *'diverged'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}&*" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'behind'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}&" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'Your branch is ahead of'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}*" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'new file:'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}+" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'deleted:'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}x" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'modified:'*)
      if [ "$1" = 'ksh' ]; then
        POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!!"
      else
        POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!"
      fi
      ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'renamed:'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}>" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'Untracked files'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}?" ;;
  esac

  [ "$POLYGLOT_SYMBOLS" ] && printf ' %s' "$POLYGLOT_SYMBOLS"

  unset POLYGLOT_GIT_STATUS POLYGLOT_SYMBOLS
}

###########################################################
# Tests to see if the current shell is busybox ash
###########################################################
_polyglot_is_busybox() {
  case $0 in
    ash|sh)
      if command -v readlink > /dev/null 2>&1; then
        case $(exec 2> /dev/null; readlink /proc/$$/exe) in
          */busybox) return 0 ;;
          *) return 1 ;;
        esac
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

###########################################################
# Test to see if the current shell is pdksh
###########################################################
_polyglot_is_pdksh() {
  case $KSH_VERSION in
    *'PD KSH'*)
      case $(uname -s) in
        OpenBSD) POLYGLOT_KSH_BANG=ksh ;;
      esac
      return 0
      ;;
    *) return 1 ;;
  esac
}

############################################################
# Emulation of bash's PROMPT_DIRTRIM for zsh, ksh, and mksh
#
# In $PWD, substitute $HOME with ~; if the remainder of the
# $PWD has more than a certain number of directory elements
# to display (default: 2), abbreviate it with '...', e.g.
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
_polyglot_ksh_prompt_dirtrim() {
  # shellcheck disable=SC2015
  [ -n "$1" ] && [ "$1" -gt 0 ] || set 2

  typeset dir dir_minus_slashes dir_count
  dir=${PWD#$HOME}
  dir_minus_slashes=${dir//\//}
  dir_count=$((${#dir} - ${#dir_minus_slashes}))

  if [ "$dir_count" -le "$1" ]; then
    case $PWD in
      ${HOME}*) printf '~%s' "${PWD#$HOME}" ;;
      *) printf '%s' "$PWD" ;;
    esac
  else
    typeset lopped_path i
    lopped_path=${PWD#$HOME}
    i=0
    while [ "$i" -ne "$1" ]; do
      lopped_path=${lopped_path%\/*}
      i=$((i+1))
    done

    case $PWD in
      ${HOME}*)
        printf '~/...%s' "${dir#${lopped_path}}"
        ;;
      *) printf '...%s' "${PWD#${lopped_path}}" ;;
    esac
  fi
}

#####################################################################
# zsh
#####################################################################
if [ -n "$ZSH_VERSION" ]; then
  setopt PROMPT_SUBST

  ###########################################################
  # Runs right before the prompt is displayed
  # Imitates bash's PROMPT_DIRTRIM behavior and calculates
  # working branch and working copy status
  ###########################################################
  _polyglot_precmd() {
    psvar[2]=$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")
    # shellcheck disable=SC2119
    psvar[3]=$(_polyglot_branch_status)
  }

  ###########################################################
  # When in vi mode, the prompt will use a bash 4.3-style
  # mode indicator at the beginning of the line -- '+' for
  # insert mode, ':' for command mode.
  ###########################################################
  _polyglot_zsh_vi_mode_indicator() {
    case $(bindkey -lL main) in
      *viins*)
        case $KEYMAP in
          vicmd) print -n ':' ;;
          *) print -n '+' ;;
        esac
        ;;
      *) ;;
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

  autoload add-zsh-hook
  add-zsh-hook precmd _polyglot_precmd

  # Only display the $HOSTNAME for an ssh connection, except for a superuser
  if _polyglot_is_ssh || _polyglot_is_superuser; then
    psvar[1]=$(print -P '@%m')
  else
    psvar[1]=''
  fi

  unset RPROMPT               # Clean up detritus from previously loaded prompts

  if _polyglot_has_colors; then
    PS1='$(_polyglot_zsh_vi_mode_indicator)%(?..%B%F{red}(%?%)%b%f )'
    PS1+='%(!.%S.%B%F{green})%n%1v%(!.%s.%f%b) '
    PS1+='%B%F{blue}%2v%f%b'
    PS1+='%F{yellow}%3v%f %# '
  else
    PS1='$(_polyglot_zsh_vi_mode_indicator)%(?..(%?%) )'
    PS1+='%(!.%S.)%n%1v%(!.%s.) '
    PS1+='%2v'
    PS1+='%3v %# '
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
    # $POLYGLOT_PROMPT_DIRTRIM must be greater than 0 and defaults to 2
    [ -n "$1" ] && [ "$1" -gt 0 ] && PROMPT_DIRTRIM=$1 || PROMPT_DIRTRIM=2

    if ! _polyglot_is_superuser; then
      if _polyglot_has_colors; then
        PS1="\[\e[01;31m\]\$(_polyglot_exit_status \$?)\[\e[0m\]"
        PS1+="\[\e[01;32m\]\u$(echo -n "$POLYGLOT_HOSTNAME_STRING")\[\e[0m\] "
        PS1+="\[\e[01;34m\]\w\[\e[0m\]"
        PS1+="\[\e[33m\]\$(_polyglot_branch_status)\[\e[0m\] \$ "
      else
        PS1="\$(_polyglot_exit_status \$?)"
        PS1+="\u$(echo -n "$POLYGLOT_HOSTNAME_STRING") "
        PS1+="\w"
        PS1+="\$(_polyglot_branch_status) \$ "
      fi
    else  # Superuser
      if _polyglot_has_colors; then
        PS1="\[\e[01;31m\]\$(_polyglot_exit_status \$?)\[\e[0m\]"
        PS1+="\[\e[7m\]\u@\h\[\e[0m\] "
        PS1+="\[\e[01;34m\]\w\[\e[0m\]"
        PS1+="\[\e[33m\]\$(_polyglot_branch_status)\[\e[0m\] \$ "
      else
        PS1="\$(_polyglot_exit_status \$?)"
        PS1+="\[\e[7m\]\u@\h\[\e[0m\] "
        PS1+="\w"
        PS1+="\$(_polyglot_branch_status) \$ "
      fi
    fi
  }

  # Only display the $HOSTNAME for an ssh connection
  if _polyglot_is_ssh; then
    POLYGLOT_HOSTNAME_STRING='@\h'
  else
    POLYGLOT_HOSTNAME_STRING=''
  fi

  PROMPT_COMMAND='_polyglot_prompt_command $POLYGLOT_PROMPT_DIRTRIM'

  # vi command mode
  if [ "$TERM" != 'dumb' ]; then     # Line editing not enabled in Emacs shell
    bind 'set show-mode-in-prompt'                      # Since bash 4.3
    bind 'set vi-ins-mode-string "+"'
    bind 'set vi-cmd-mode-string ":"'
  fi
#####################################################################
# ksh93 and mksh
#####################################################################

elif [ -n "$KSH_VERSION" ] && ! _polyglot_is_pdksh ; then
  # Only display the $HOSTNAME for an ssh connection
  if _polyglot_is_ssh || _polyglot_is_superuser; then
    POLYGLOT_HOSTNAME_STRING=$(hostname)
    POLYGLOT_HOSTNAME_STRING="@${POLYGLOT_HOSTNAME_STRING%?${POLYGLOT_HOSTNAME_STRING#*.}}"
  else
    POLYGLOT_HOSTNAME_STRING=''
  fi

  case $KSH_VERSION in
    *MIRBSD*)
      # To know how long the prompt is, and thus to know how far it is to the
      # edge of the screen, mksh requires an otherwise unused character (in this
      # case \001) followed by a carriage return at the beginning of the
      # prompt, which is then used to mark off escape sequences as zero-length.
      # See https://www.mirbsd.org/htman/i386/man1/mksh.htm
      if ! _polyglot_is_superuser; then
        if _polyglot_has_colors; then
          PS1=$(print "\001\r\001\E[31;1m\001")
          PS1+='$(_polyglot_exit_status $?)'
          PS1+=$(print "\001\E[0m\E[32;1m\001")
          PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' '
          PS1+=$(print "\001\E[34;1m\001")
          PS1+='$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+=$(print "\001\E[0m\E[33m\001")
          PS1+='$(_polyglot_branch_status)'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' \$ '
        else
          PS1='$(_polyglot_exit_status $?)'
          PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING '
          PS1+='$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+='$(_polyglot_branch_status) $ '
        fi
      else # Superuser
        if _polyglot_has_colors; then
          PS1=$(print "\001\r\001\E[31;1m\001")
          PS1+='$(_polyglot_exit_status $?)'
          PS1+=$(print "\001\E[0m\E[7m\001")
          PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' '
          PS1+=$(print "\001\E[34;1m\001")
          PS1+='$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+=$(print "\001\E[0m\E[33m\001")
          PS1+='$(_polyglot_branch_status)'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' \$ '
        else
          PS1=$(print "\001\r")
          PS1+='$(_polyglot_exit_status $?)'
          PS1+=$(print "\001\E[7m\001")
          PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' '
          PS1+='$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+='$(_polyglot_branch_status) $ '
        fi
      fi
      ;;
    *)
      # ksh93 is better at calculating prompt length and wrapping, but requires
      # escaping ! as !! to prevent display of history line
      if ! _polyglot_is_superuser; then
        if _polyglot_has_colors; then
          # FreeBSD sh chokes on ANSI C quoting, so I'll avoid it
          # shellcheck disable=2016
          PS1='\E[31;1m$(_polyglot_exit_status $?)\E[0m'
          PS1+='\E[32;1m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m '
          PS1+='\E[34;1m$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")\E[0m'
          PS1+='\E[33m$(_polyglot_branch_status ksh)\E[0m \$ '
          PS1=$(print "$PS1")
        else
          PS1='$(_polyglot_exit_status $?)'
          PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING '
          PS1+='$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+='$(_polyglot_branch_status ksh) \$ '
        fi
      else  # Superuser
        if _polyglot_has_colors; then
          PS1='\E[31;1m$(_polyglot_exit_status $?)\E[0m'
          PS1+='\E[7m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m '
          PS1+='\E[34;1m$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")\E[0m'
          PS1+='\E[33m$(_polyglot_branch_status ksh)\E[0m \$ '
          PS1=$(print "$PS1")
        else
          PS1='$(_polyglot_exit_status $?)'
          PS1+='\E[7m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m '
          PS1+='$(_polyglot_ksh_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+='$(_polyglot_branch_status ksh) \$ '
          PS1=$(print "$PS1")
        fi
      fi
      ;;
  esac

####################################################################
# pdksh, dash, and busybox ash
####################################################################

elif _polyglot_is_pdksh || [ "$0" = 'dash' ] || _polyglot_is_busybox; then
  ############################################################
  # Emulation of bash's PROMPT_DIRTRIM for pdksh, dash, and busybox ash
  #
  # In $PWD, substitute $HOME with ~; if the remainder of the
  # $PWD has more than a certain number of directory elements
  # to display (default: 2), abbreviate it with '...', e.g.
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
    # $POLYGLOT_PROMPT_DIRTRIM must be greater than 0 and defaults to 2
    # shellcheck disable=SC2015
    [ -n "$1" ] && [ "$1" -gt 0 ] || set 2

    # Calculate the part of $PWD that will be displayed in the prompt
    POLYGLOT_ABBREVIATED_PATH=$(echo "${PWD#$HOME}" | awk -F/ '{
      dir_count=NF-1;
      if (dir_count <= '"$1"')
        print $0;
      else
        for (i=NF-'"$1"'+1; i<=NF; i++) printf "/%s", $i;
    }')

    # If the working directory has not been abbreviated, display it thus
    if [ "$POLYGLOT_ABBREVIATED_PATH" = "${PWD#$HOME}" ]; then
      case $PWD in
        ${HOME}*) printf '~%s' "${PWD#$HOME}" ;;
        *) printf '%s' "$PWD" ;;
      esac
    # Otherwise include an ellipsis to show that abbreviation has taken place
    else
      case $PWD in
        ${HOME}*) printf '~/...%s' "$POLYGLOT_ABBREVIATED_PATH" ;;
        *) printf '...%s' "$POLYGLOT_ABBREVIATED_PATH" ;;
      esac
    fi

    unset POLYGLOT_ABBREVIATED_PATH
  }

  # Only display the $HOSTNAME for an ssh connection
  if _polyglot_is_ssh || _polyglot_is_superuser; then
    POLYGLOT_HOSTNAME_STRING=$(hostname)
    POLYGLOT_HOSTNAME_STRING="@${POLYGLOT_HOSTNAME_STRING%?${POLYGLOT_HOSTNAME_STRING#*.}}"
  else
    POLYGLOT_HOSTNAME_STRING=''
  fi

  if ! _polyglot_is_superuser; then
    PS1='$(_polyglot_exit_status $?)${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) $ '
  else  # Superuser
    case $(uname) in
      *BSD*|DragonFly*)
        POLYGLOT_REV=$(tput mr)
        POLYGLOT_RESET=$(tput me)
        ;;
      *)
        POLYGLOT_REV=$(tput rev)
        POLYGLOT_RESET=$(tput sgr0)
        ;;
    esac

    PS1='$(_polyglot_exit_status $?)${POLYGLOT_REV}${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING${POLYGLOT_RESET} $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) $ '
  fi

else
  printf '%s\n' 'Polyglot Prompt does not support your shell.' >&2
fi

# Clean up environment
unset -f _polyglot_is_ssh _polyglot_is_busybox _polyglot_is_pdksh

# vim: ts=2:et:sts=2:sw=2

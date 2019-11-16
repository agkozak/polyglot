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
# Set $POLYGLOT_PROMPT_DIRTRIM to the number of directory elements you would
# like to have displayed in your prompt (the default is 2). For example,
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
# Copyright 2017-2019 Alexandros Kozak
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

# shellcheck disable=SC2016,SC2034,SC2088

# Only run in interactive shells
case $- in
  *i*) ;;
  *) exit ;;
esac

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
  [ "${SSH_CONNECTION-}${SSH_CLIENT-}${SSH_TTY-}" ]
}

###########################################################
# Provide the effective user ID
###########################################################
_polyglot_euid() {
  case ${POLYGLOT_UNAME:=$(uname -s)} in
    SunOS) /usr/xpg4/bin/id -u ;;
    *) id -u ;;
  esac
}

###########################################################
# Is the user a superuser?
###########################################################
_polyglot_is_superuser() {
  [ ${EUID:-$(_polyglot_euid)} -eq 0 ]
}

###########################################################
# Does the terminal support enough colors?
###########################################################
_polyglot_has_colors() {
  # The DragonFly BSD system console has trouble displaying colors in pdksh
  case ${POLYGLOT_UNAME:=$(uname -s)} in
    DragonFly)
      case $(who am i) in *ttyv*) return 1 ;; esac
      ;;
  esac

  case $TERM in
    *-256color) POLYGLOT_TERM_COLORS=256 ;;
    vt100|dumb) POLYGLOT_TERM_COLORS=-1 ;;
    *)
      if command -v tput > /dev/null 2>&1; then
        case ${POLYGLOT_UNAME:=$(uname -s)} in
          FreeBSD|DragonFly) POLYGLOT_TERM_COLORS=$(tput Co) ;;
          *) POLYGLOT_TERM_COLORS=$(tput colors) ;;
        esac
      else
        POLYGLOT_TERM_COLORS=-1
      fi
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

############################################################
# Emulation of bash's PROMPT_DIRTRIM for all other shells
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
# If $1 is 0, no abbreviation will occur other than that
# $HOME will be displayed as ~.
#
# Arguments:
#   $1 Number of directory elements to display
############################################################
_polyglot_prompt_dirtrim() {
  # Necessary for set -- $1 to undergo field separation in zsh
  [ "$ZSH_VERSION" ] && setopt LOCAL_OPTIONS SH_WORD_SPLIT

  # $POLYGLOT_PROMPT_DIRTRIM must be greater than 0 and defaults to 2
  POLYGLOT_DIRTRIM_ELEMENTS="${1:-2}"

  # If root has / as $HOME, print /, not ~
  [ "$PWD" = '/' ] && printf '%s' '/' && return
  [ "$PWD" = "$HOME" ] && printf '%s' '~' && return

  case $HOME in
    /) POLYGLOT_PWD_MINUS_HOME="$PWD" ;;            # In case root's $HOME is /
    *) POLYGLOT_PWD_MINUS_HOME="${PWD#$HOME}" ;;
  esac

  if [ "$POLYGLOT_DIRTRIM_ELEMENTS" -eq 0 ]; then
    [ "$HOME" = '/' ] && printf '%s' "$PWD" && return
    case $PWD in
      ${HOME}*) printf '~%s' "$POLYGLOT_PWD_MINUS_HOME" ;;
      *) printf '%s' "$PWD" ;;
    esac
  else
    # Calculate the part of $PWD that will be displayed in the prompt
    POLYGLOT_OLD_IFS="$IFS"
    IFS='/'
    # shellcheck disable=SC2086
    set -- $POLYGLOT_PWD_MINUS_HOME
    shift                                  # Discard empty first field preceding /

    # Discard path elements > $POLYGLOT_PROMPT_DIRTRIM
    while [ $# -gt "$POLYGLOT_DIRTRIM_ELEMENTS" ]; do
      shift
    done

    # Reassemble the remaining path elements with slashes
    while [ $# -ne 0 ]; do
      POLYGLOT_ABBREVIATED_PATH="${POLYGLOT_ABBREVIATED_PATH}/$1"
      shift
    done

    IFS="$POLYGLOT_OLD_IFS"

    # If the working directory has not been abbreviated, display it thus
    if [ "$POLYGLOT_ABBREVIATED_PATH" = "${POLYGLOT_PWD_MINUS_HOME}" ]; then
      if [ "$HOME" = '/' ]; then
        printf '%s' "$PWD"
      else
        case $PWD in
          ${HOME}*) printf '~%s' "${POLYGLOT_PWD_MINUS_HOME}" ;;
          *) printf '%s' "$PWD" ;;
        esac
      fi
    # Otherwise include an ellipsis to show that abbreviation has taken place
    else
      if [ "$HOME" = '/' ]; then
        printf '...%s' "$POLYGLOT_ABBREVIATED_PATH"
      else
        case $PWD in
          ${HOME}*) printf '~/...%s' "$POLYGLOT_ABBREVIATED_PATH" ;;
          *) printf '...%s' "$POLYGLOT_ABBREVIATED_PATH" ;;
        esac
      fi
    fi
  fi

  unset POLYGLOT_DIRTRIM_ELEMENTS POLYGLOT_PWD_MINUS_HOME POLYGLOT_OLD_IFS \
    POLYGLOT_ABBREVIATED_PATH
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
  [ "$ZSH_VERSION" ] && \
    setopt LOCAL_OPTIONS NO_WARN_CREATE_GLOBAL NO_WARN_NESTED_VAR > /dev/null 2>&1
  POLYGLOT_REF=$(env git symbolic-ref --quiet HEAD 2> /dev/null)
  case $? in        # See what the exit code is.
    0) ;;           # $POLYGLOT_REF contains the name of a checked-out branch.
    128) return ;;  # No Git repository here.
    # Otherwise, see if HEAD is in a detached state.
    *) POLYGLOT_REF=$(env git rev-parse --short HEAD 2> /dev/null) || return ;;
  esac

  if [ "$POLYGLOT_REF" ]; then
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
  [ "$ZSH_VERSION" ] && \
    setopt LOCAL_OPTIONS NO_WARN_CREATE_GLOBAL NO_WARN_NESTED_VAR > /dev/null 2>&1

  POLYGLOT_GIT_STATUS=$(LC_ALL=C GIT_OPTIONAL_LOCKS=0 env git status 2>&1)

  POLYGLOT_SYMBOLS=''

  case $POLYGLOT_GIT_STATUS in
    *' have diverged,'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}&*" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'Your branch is behind '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}&" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'Your branch is ahead of '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}*" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'new file:   '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}+" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'deleted:    '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}x" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'modified:   '*)
      if [ "$1" = 'ksh' ]; then
        POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!!"
      else
        POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}!"
      fi
      ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'renamed:    '*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}>" ;;
  esac
  case $POLYGLOT_GIT_STATUS in
    *'Untracked files:'*) POLYGLOT_SYMBOLS="${POLYGLOT_SYMBOLS}?" ;;
  esac

  [ "$POLYGLOT_SYMBOLS" ] && printf ' %s' "$POLYGLOT_SYMBOLS"

  unset POLYGLOT_GIT_STATUS POLYGLOT_SYMBOLS
}

###########################################################
# Native sh alternative to basename. See
# https://github.com/dylanaraps/pure-sh-bible
#
# Arguments:
#   $1 Filename
#   $2 Suffix
###########################################################
_polyglot_basename() {
  POLYGLOT_BASENAME_DIR=${1%${1##*[!/]}}
  POLYGLOT_BASENAME_DIR=${POLYGLOT_BASENAME_DIR##*/}
  POLYGLOT_BASENAME_DIR=${POLYGLOT_BASENAME_DIR%"$2"}

  printf '%s\n' "${POLYGLOT_BASENAME_DIR:-/}"

  unset POLYGLOT_BASENAME_DIR
}

###########################################################
# Tests to see if the current shell is busybox ash
###########################################################
_polyglot_is_busybox() {
  case $(_polyglot_basename "$0") in
    ash|-ash|sh|-sh)
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
      [ "${POLYGLOT_UNAME:=$(uname -s)}" = 'OpenBSD' ] && POLYGLOT_KSH_BANG='ksh'
      return 0
      ;;
    *) return 1 ;;
  esac
}

###########################################################
# Test to see if the currect shell is dtksh (Desktop Korn
# Shell).
###########################################################
_polyglot_is_dtksh() {
  case $0 in
    *dtksh) return 0 ;;
    *) return 1 ;;
  esac
}

#####################################################################
# zsh
#####################################################################

# Make sure that ZSH is not emulating ksh or bash
if [ "$ZSH_VERSION" ] && [ "$0" != 'ksh' ] \
  && [ "$0" != 'bash' ] && [ "$0" != 'sh' ]; then

  setopt PROMPT_SUBST

  ###########################################################
  # Runs right before the prompt is displayed
  # Imitates bash's PROMPT_DIRTRIM behavior and calculates
  # working branch and working copy status
  ###########################################################
  _polyglot_precmd() {
    psvar[2]=$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")
    psvar[3]=$(_polyglot_branch_status)
  }

  ###########################################################
  # Redraw the prompt when the vi mode changes
  #
  # Whn in vi mode, the prompt will use a bash 4.3-style
  # mode indicator at the beginniing of the line: '+' for
  # insert mode; ':' for command mode
  #
  # Underscores are used in this function's name to keep
  # dash from choking on hyphens
  ###########################################################
  _polyglot_zle_keymap_select() {
    [ "$KEYMAP" = 'vicmd' ] && psvar[4]='vicmd' || psvar[4]=''
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

  # TODO: add-zsh-hook was added in ZSH v4.3.4. It would be nice to be
  # compatible with even earlier versions of ZSH, but that seems to require
  # use of array syntax that is incompatible with ash.
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
    PS1='%(4V.:.+)%(?..%B%F{red}(%?%)%b%f )'
    PS1+='%(!.%S.%B%F{green})%n%1v%(!.%s.%f%b) '
    PS1+='%B%F{blue}%2v%f%b'
    PS1+='%F{yellow}%3v%f %# '
  else
    PS1='%(4V.:.+)%(?..(%?%) )'
    PS1+='%(!.%S.)%n%1v%(!.%s.) '
    PS1+='%2v'
    PS1+='%3v %# '
  fi

#####################################################################
# bash
#####################################################################
elif [ "$BASH_VERSION" ]; then

  ###########################################################
  # Create the bash $PROMPT_COMMAND
  #
  # If $1 is 0, bash's PROMPT_DIRTRIM abbreviations will be
  # disabled; the only abbreviation that will occur is that
  # $HOME will be displayed as ~.
  #
  # Arguments:
  #   $1 Number of directory elements to display
  ###########################################################
  _polyglot_prompt_command() {
    # $POLYGLOT_PROMPT_DIRTRIM must be greater than 0 and defaults to 2
    [ "$1" ] && PROMPT_DIRTRIM=$1 || PROMPT_DIRTRIM=2

    if ! _polyglot_is_superuser; then
      if _polyglot_has_colors; then
        PS1="\[\e[01;31m\]\$(_polyglot_exit_status \$?)\[\e[0m\]"
        PS1+="\[\e[01;32m\]\u$(echo -n "$POLYGLOT_HOSTNAME_STRING")\[\e[0m\] "
        case $BASH_VERSION in
          # bash, before v4.0, did not have $PROMPT_DIRTRIM
          1\.*|2\.*|3\.*)
            PS1+="\[\e[01;34m\]\$(_polyglot_prompt_dirtrim "\$POLYGLOT_PROMPT_DIRTRIM")\[\e[0m\]"
            ;;
          *) PS1+="\[\e[01;34m\]\w\[\e[0m\]" ;;
        esac
        PS1+="\[\e[33m\]\$(_polyglot_branch_status)\[\e[0m\] \$ "
      else
        PS1="\$(_polyglot_exit_status \$?)"
        PS1+="\u$(echo -n "$POLYGLOT_HOSTNAME_STRING") "
        case $BASH_VERSION in
          1\.*|2\.*|3\.*)
           PS1="\$(_polyglot_prompt_dirtrim "\$POLYGLOT_PROMPT_DIRTRIM")"
           ;;
          *) PS1+="\w" ;;
        esac
        PS1+="\$(_polyglot_branch_status) \$ "
      fi
    else  # Superuser
      if _polyglot_has_colors; then
        PS1="\[\e[01;31m\]\$(_polyglot_exit_status \$?)\[\e[0m\]"
        PS1+="\[\e[7m\]\u@\h\[\e[0m\] "
        case $BASH_VERSION in
          1\.*|2\.*|3\.*)
            PS1+="\[\e[01;34m\]\$(_polyglot_prompt_dirtrim "\$POLYGLOT_PROMPT_DIRTRIM")\[\e[0m\]"
            ;;
          *) PS1+="\[\e[01;34m\]\w\[\e[0m\]" ;;
        esac
        PS1+="\[\e[33m\]\$(_polyglot_branch_status)\[\e[0m\] # "
      else
        PS1="\$(_polyglot_exit_status \$?)"
        PS1+="\[\e[7m\]\u@\h\[\e[0m\] "
        case $BASH_VERSION in
          1\.*|2\.*|3\.*)
            PS1+="\$(_polyglot_prompt_dirtrim "\$POLYGLOT_PROMPT_DIRTRIM")"
            ;;
          *) PS1+="\w" ;;
        esac
        PS1+="\$(_polyglot_branch_status) # "
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
# ksh93, mksh, and zsh in bash, ksh, and sh emulation mode
#####################################################################

elif [ "$KSH_VERSION" ] || _polyglot_is_dtksh || [ "$ZSH_VERSION" ] \
  && ! _polyglot_is_pdksh ; then
  # Only display the $HOSTNAME for an ssh connection
  if _polyglot_is_ssh || _polyglot_is_superuser; then
    POLYGLOT_HOSTNAME_STRING=$(hostname)
    POLYGLOT_HOSTNAME_STRING="@${POLYGLOT_HOSTNAME_STRING%?${POLYGLOT_HOSTNAME_STRING#*.}}"
  else
    POLYGLOT_HOSTNAME_STRING=''
  fi

  if [ "$0" = 'bash' ] || [ "$0" = 'sh' ]; then
    POLYGLOT_KSH_BANG=''
  else
    case $KSH_VERSION in
      *MIRBSD*) POLYGLOT_KSH_BANG='' ;;
      *) POLYGLOT_KSH_BANG='ksh' ;;
    esac
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
          PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+=$(print "\001\E[0m\E[33m\001")
          PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' \$ '
        else
          PS1='$(_polyglot_exit_status $?)'
          PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING '
          PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG) \$ '
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
          PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+=$(print "\001\E[0m\E[33m\001")
          PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' # '
        else
          PS1=$(print "\001\r")
          PS1+='$(_polyglot_exit_status $?)'
          PS1+=$(print "\001\E[7m\001")
          PS1+='${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
          PS1+=$(print "\001\E[0m\001")
          PS1+=' '
          PS1+='$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
          PS1+='$(_polyglot_branch_status $POLYGLOT_KSH_BANG) # '
        fi
      fi
      ;;
    *)
      if ! _polyglot_is_superuser; then
        # zsh emulating other shells doesn't handle colors well
        if _polyglot_has_colors && [ -z "$ZSH_VERSION" ]; then
          # FreeBSD sh chokes on ANSI C quoting, so I'll avoid it
          PS1="$(print '\E[31;1m$(_polyglot_exit_status $?)\E[0m\E[32;1m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m \E[34;1m$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")\E[0m\E[33m$(_polyglot_branch_status $POLYGLOT_KSH_BANG)\E[0m \$ ')"
        else
          PS1='$(_polyglot_exit_status $?)${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) \$ '
        fi
      else  # Superuser
        if _polyglot_has_colors && [ -z "$ZSH_VERSION" ]; then
          PS1="$(print '\E[31;1m$(_polyglot_exit_status $?)\E[0m\E[7m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m \E[34;1m$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")\E[0m\E[33m$(_polyglot_branch_status $POLYGLOT_KSH_BANG)\E[0m # ')"
        else
          PS1="$(print '$(_polyglot_exit_status $?)\E[7m${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING\E[0m $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) # ')"
        fi
      fi
      ;;
  esac

####################################################################
# pdksh, dash, busybox ash, and zsh in sh emulation mode
####################################################################

elif _polyglot_is_pdksh || [ "$0" = 'dash' ] || _polyglot_is_busybox; then

  # Only display the $HOSTNAME for an ssh connection
  if _polyglot_is_ssh || _polyglot_is_superuser; then
    POLYGLOT_HOSTNAME_STRING=$(hostname)
    POLYGLOT_HOSTNAME_STRING="@${POLYGLOT_HOSTNAME_STRING%?${POLYGLOT_HOSTNAME_STRING#*.}}"
  else
    POLYGLOT_HOSTNAME_STRING=''
  fi

  # A non-printable character (Ctrl-Q) for delimiting escape sequences in pdksh
  POLYGLOT_NP="\021"

  if _polyglot_is_pdksh && _polyglot_has_colors; then

    PS1=$(print "$POLYGLOT_NP\r")
    case $POLYGLOT_UNAME in
      NetBSD*|OpenBSD*) PS1=$PS1$(print "$POLYGLOT_NP") ;;
    esac
    PS1=$PS1$(print "\033[31;1m$POLYGLOT_NP")
    PS1=$PS1'$(_polyglot_exit_status $?)'
    if ! _polyglot_is_superuser; then
      PS1=$PS1$(print "$POLYGLOT_NP\033[0m\033[32;1m$POLYGLOT_NP")
    else
      PS1=$PS1$(print "$POLYGLOT_NP\033[0m\033[7m$POLYGLOT_NP")
    fi
    PS1=$PS1'${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
    PS1=$PS1$(print "$POLYGLOT_NP\033[0m$POLYGLOT_NP")
    PS1=$PS1' '
    PS1=$PS1$(print "$POLYGLOT_NP\033[34;1m$POLYGLOT_NP")
    PS1=$PS1'$(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")'
    PS1=$PS1$(print "$POLYGLOT_NP\033[0m\033[33m$POLYGLOT_NP")
    PS1=$PS1'$(_polyglot_branch_status $POLYGLOT_KSH_BANG)'
    PS1=$PS1$(print "$POLYGLOT_NP\033[0m$POLYGLOT_NP")
    PS1=$PS1' \$ '

  elif ! _polyglot_is_superuser; then
    PS1='$(_polyglot_exit_status $?)${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) \$ '
  else  # Superuser

    ##########################################################
    # Tests to see if the terminal is the DragonFly BSD system
    # console, which displays color in pdksh badly.
    ##########################################################
    _polyglot_is_dragonfly_console() {
      case ${POLYGLOT_UNAME:=$(uname -s)} in
        DragonFly)
          case $(who am i) in
            *ttyv*) return 0 ;;
            *) return 1 ;;
          esac
          ;;
        *) return 1 ;;
      esac
    }

    PS1=
    _polyglot_is_pdksh && ! _polyglot_is_dragonfly_console && PS1=$(print "$POLYGLOT_NP\r")
    PS1=$PS1'$(_polyglot_exit_status $?)'
    if _polyglot_is_pdksh && ! _polyglot_is_dragonfly_console; then
      case $POLYGLOT_UNAME in
        NetBSD|OpenBSD) PS1="$PS1$(print "$POLYGLOT_NP")" ;;
      esac
    fi
    # shellcheck disable=SC2025
    ! _polyglot_is_dragonfly_console && [ "$0" != 'dash' ] && PS1="$PS1\033[7m"
    _polyglot_is_pdksh && ! _polyglot_is_dragonfly_console && PS1=$PS1$(print "$POLYGLOT_NP")
    PS1=$PS1'${LOGNAME:-$(logname)}$POLYGLOT_HOSTNAME_STRING'
    _polyglot_is_pdksh && ! _polyglot_is_dragonfly_console && PS1=$PS1$(print "$POLYGLOT_NP")
    # shellcheck disable=SC2025
    ! _polyglot_is_dragonfly_console && [ "$0" != 'dash' ] && PS1="$PS1\033[0m"
    _polyglot_is_pdksh && ! _polyglot_is_dragonfly_console && PS1=$PS1$(print "$POLYGLOT_NP")
    PS1=$PS1' $(_polyglot_prompt_dirtrim "$POLYGLOT_PROMPT_DIRTRIM")$(_polyglot_branch_status $POLYGLOT_KSH_BANG) # '
  fi

else
  printf '%s\n' 'Polyglot Prompt does not support your shell.' >&2
fi

# Clean up environment
unset -f _polyglot_is_ssh _polyglot_basename _polyglot_is_busybox \
  _polyglot_is_dtksh _polyglot_is_pdksh

# vim: ts=2:et:sts=2:sw=2

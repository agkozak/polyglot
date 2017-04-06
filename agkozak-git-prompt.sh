#              _                 _
#   __ _  __ _| | _____ ______ _| | __
#  / _` |/ _` | |/ / _ \_  / _` | |/ /
# | (_| | (_| |   < (_) / / (_| |   <
#  \__,_|\__, |_|\_\___/___\__,_|_|\_\
#        |___/
#
# agkozak Git prompt
#
# https://github.com/agkozak/agkozak-git-prompt
#

# shellcheck disable=SC2148

# Display current branch and status
_branch_status() {
  ref=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  exit=$?
  if [ $exit -ne 0 ]; then
    [ $exit -eq 128 ] && return  # No git repository here.
    ref=$(git rev-parse --short HEAD 2> /dev/null) || return
  fi
  branch=${ref#refs/heads/}
  echo " (${branch}$(_branch_changes))"
}

# Display status of current branch
_branch_changes() {
  git_status=$(git status 2>&1)

  symbols=''

  case "$git_status" in
    *'renamed:'*) symbols=">${symbols}";;
  esac
  case "$git_status" in
    *'Your branch is ahead of'*) symbols="*${symbols}";;
  esac
  case "$git_status" in
    *'new file:'*) symbols="+${symbols}";;
  esac
  case "$git_status" in
    *'Untracked files'*) symbols="?${symbols}";;
  esac
  case "$git_status" in
    *'deleted:'*) symbols="x${symbols}";;
  esac
  case "$git_status" in
    *'modified:'*) symbols="!${symbols}";;
  esac

  if [ "$symbols" = '' ]; then
    echo ''
  else
    echo " $symbols"
  fi
}

_branch_status_with_bang() {
  ksh_branch_status=$(_branch_status)
  echo "${ksh_branch_status/!/!!}"
}

export HOSTNAME
HOSTNAME=$(hostname)

if [ -n "$ZSH_VERSION" ]; then
  setopt PROMPT_SUBST

  # Autoload zsh colors module if it hasn't been autoloaded already
  if ! whence -w colors > /dev/null 2>&1; then
    autoload -Uz colors
    colors
  fi

  # shellcheck disable=SC2154
  mode_indicator="%{$fg_bold[black]%}%{$bg[white]%}"

  # shellcheck disable=SC2154
  PS1='%{$fg_bold[green]%}%n@%m%{$reset_color%} %{$fg_bold[blue]%}%(3~|%2~|%~)%{$reset_color%}%{$fg[yellow]%}$(_branch_status)%{$reset_color%}${${KEYMAP/vicmd/$mode_indicator}/(main|viins)/} %#%{$reset_color%} '

  # The right prompt will show the exit code if it is not zero.
  # shellcheck disable=SC2034
  RPS1="%(?..%{$fg_bold[red]%}(%?%)%{$reset_color%})"
elif [ -n "$BASH_VERSION" ]; then
  export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\e[m\]\[\e[0;33m\]\`_branch_status\`\[\e[m\]\\$ "
elif [ -n "$KSH_VERSION" ]; then
  case "$KSH_VERSION" in
    *MIRBSD*)
      PS1='$LOGNAME@$HOSTNAME $(echo $PWD | sed "s,^$HOME,~,")$(_branch_status) \$ '
    ;;
    *)
      case $TERM in
        *-256color)
          # shellcheck disable=SC2039
          PS1=$'\E[32;1m$LOGNAME@$HOSTNAME\E[0m \E[34;1m$(echo $PWD | sed "s,^$HOME,~,")\E[0m\E[33m$(_branch_status_with_bang)\E[0m \$ '
        ;;
        *)
          PS1='$LOGNAME@$HOSTNAME $(echo $PWD | sed "s,^$HOME,~,")$(_branch_status_with_bang) \$ '
        ;;
      esac
    ;;
  esac
  return
elif [ "$(basename "$0")" = 'dash' ]; then
  PS1='$LOGNAME@$HOSTNAME $(echo $PWD | sed "s,^$HOME,~,")$(_branch_status) $ '
else
  echo 'agkozak-git-prompt does not yet support your shell.'
fi

# vim:filetype=sh foldmethod=marker tabstop=2 expandtab

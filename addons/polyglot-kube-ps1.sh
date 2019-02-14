# Polyglot integration with kube-ps1 (https://github.com/jonmosco/kube-ps1)

# Check to make sure that kube-ps1 has been loaded
if ! type kube_ps1 &> /dev/null; then
  echo 'polyglot-kube-ps1: Load jonmosco/kube-ps1.' >&2 && return 1
fi

# Do not show the unicode Kubernetes symbol and use yellow, unless there is an existing
# explicit configuration
KUBE_PS1_SYMBOL_ENABLE=${KUBE_PS1_SYMBOL_ENABLE:-false}
KUBE_PS1_CTX_COLOR=${KUBE_PS1_CTX_COLOR:-yellow}

if [[ -n $ZSH_VERSION ]]; then

  _polyglot_kube_ps1_precmd() {
    local kube_ps1=$(kube_ps1)
    if [[ -n $kube_ps1 ]]; then
      if _polyglot_has_colors; then
        print -P "%B$kube_ps1%b"
      else
        print "$kube_ps1"
      fi
    fi
  }

  add-zsh-hook precmd _polyglot_kube_ps1_precmd

elif [[ -n $BASH_VERSION ]]; then

  _polyglot_kube_ps1_prompt_command() {
    # Required, as polyglot redefines PROMPT_COMMAND and removes it
    _kube_ps1_update_cache
    local kube_ps1=$(kube_ps1)
    if [ -n "$kube_ps1" ]; then
      if _polyglot_has_colors; then
        PS1="\033[1m\]$kube_ps1\[\033[0m\]\n"$PS1
      else
        PS1="$kube_ps1"$PS1
      fi
    fi
  }

  if [[ $PROMPT_COMMAND != *_polyglot_kube_ps1_prompt_command* ]]; then
    PROMPT_COMMAND+=';_polyglot_kube_ps1_prompt_command'
  fi

fi

# Polyglot Prompt shim for zsh frameworks

# shellcheck disable=SC2148

# Compile polyglot.sh with zcompile when necessary
if [[ ${0:a:h}/polyglot.sh -nt ${0:a:h}/polyglot.sh.zwc ]] || [[ ! -e ${0:a:h}/polyglot.sh.zwc ]]; then
  zcompile "${0:a:h}/polyglot.sh"
fi

#shellcheck source=/dev/null
 . "${0:a:h}/polyglot.sh"

# Polyglot Prompt shim for zsh frameworks

# shellcheck disable=SC2148

# Compile polyglot.sh with zcompile when necessary
if [[ ${0:A:h}/polyglot.sh -nt ${0:A:h}/polyglot.sh.zwc ]] || [[ ! -e ${0:A:h}/polyglot.sh.zwc ]]; then
  zcompile -R "${0:A:h}/polyglot.sh"
fi

#shellcheck source=/dev/null
 . "${0:A:h}/polyglot.sh"

# shellcheck disable=SC2148

# Compile agkozak-git-prompt.sh with zcompile when necessary
if [ "${0:a:h}/agkozak-git-prompt.sh" -nt "${0:a:h}/agkozak-git-prompt.sh.zwc" ] || [ ! -e "${0:a:h}/agkozak-git-prompt.sh.zwc" ]; then
  zcompile "${0:a:h}/agkozak-git-prompt.sh"
fi

#shellcheck source=/dev/null
 . "${0:a:h}/agkozak-git-prompt.sh"

#!/bin/sh
# Run from the repository root in an interactive shell, for example:
#   TERM=dumb bash --noprofile --norc -i -c '. ./tests/nix.sh'
#   TERM=dumb zsh -f -i -c '. ./tests/nix.sh'
#   TERM=dumb dash -i -c '. ./tests/nix.sh'
#   TERM=dumb ksh -i -c '. ./tests/nix.sh'
# No Nix installation is needed; environment markers are simulated.

# shellcheck shell=ksh
# shellcheck disable=SC2016,SC2034

case $- in
  *i*) ;;
  *) printf '%s\n' 'Run these tests in an interactive shell with -i.' >&2; exit 1 ;;
esac

unset IN_NIX_SHELL NIX_BUILD_TOP POLYGLOT_NIX_LABEL \
  VIRTUAL_ENV PIPENV_ACTIVE CONDA_DEFAULT_ENV

. ./polyglot.sh || exit 1
command -v _polyglot_env > /dev/null 2>&1 || exit 1

# All shells must defer environment detection until the prompt is rendered.
if [ -n "${ZSH_VERSION-}" ]; then
  _polyglot_precmd
elif [ -n "${BASH_VERSION-}" ]; then
  _polyglot_prompt_command "${POLYGLOT_PROMPT_DIRTRIM-}"
fi
case $PS1 in
  *'%5v'*|*'$(_polyglot_env)'*) ;;
  *) printf '%s\n' 'Missing dynamic environment labels in PS1.' >&2; exit 1 ;;
esac

POLYGLOT_TEST_COUNT=0
assert_env() {
  POLYGLOT_TEST_ACTUAL=$(_polyglot_env)
  if [ "$POLYGLOT_TEST_ACTUAL" != "$2" ]; then
    printf '%s: expected <%s>, got <%s>\n' "$1" "$2" "$POLYGLOT_TEST_ACTUAL" >&2
    exit 1
  fi

  # Zsh stores labels in psvar; check that it refreshes after each change.
  if [ -n "${ZSH_VERSION-}" ]; then
    _polyglot_precmd
    if [ "${psvar[5]}" != "$2" ]; then
      printf '%s: Zsh environment labels did not refresh.\n' "$1" >&2
      exit 1
    fi
  fi
  POLYGLOT_TEST_COUNT=$((POLYGLOT_TEST_COUNT + 1))
}

assert_env 'outside Nix' ''
POLYGLOT_NIX_LABEL='my-project'
assert_env 'a label alone does not activate Nix detection' ''
unset POLYGLOT_NIX_LABEL

IN_NIX_SHELL=impure
assert_env 'impure Nix shell' '(nix) '
IN_NIX_SHELL=pure
assert_env 'pure Nix shell' '(nix) '
IN_NIX_SHELL=''
assert_env 'empty marker' ''
unset IN_NIX_SHELL

NIX_BUILD_TOP=''
assert_env 'empty build marker' ''
NIX_BUILD_TOP='/tmp/nix-shell.test'
assert_env 'older nix develop build marker' '(nix) '
IN_NIX_SHELL=impure
assert_env 'both markers display only one label' '(nix) '

POLYGLOT_NIX_LABEL='my-project'
assert_env 'custom label' '(my-project) '
POLYGLOT_NIX_LABEL=''
assert_env 'empty label uses the default' '(nix) '
POLYGLOT_NIX_LABEL='project with spaces'
assert_env 'spaces in label' '(project with spaces) '
POLYGLOT_NIX_LABEL='100% %F{red} $(printf injected) `printf injected` ${HOME} \ !'
assert_env 'label is literal text' '(100% %F{red} $(printf injected) `printf injected` ${HOME} \ !) '
POLYGLOT_NIX_LABEL='my-project'

VIRTUAL_ENV='/tmp/my-venv'
assert_env 'Nix and virtualenv' '(my-project) (my-venv) '
VIRTUAL_ENV='/tmp/project/.venv'
assert_env 'Nix and project-local venv or poetry' '(my-project) (project) '
PIPENV_ACTIVE=1
assert_env 'Nix and project-local pipenv' '(my-project) (project) '
VIRTUAL_ENV='/tmp/project-abcdef'
assert_env 'Nix and pipenv' '(my-project) (project) '
unset VIRTUAL_ENV PIPENV_ACTIVE

CONDA_DEFAULT_ENV='data-science'
assert_env 'Nix and Conda' '(my-project) (data-science) '
VIRTUAL_ENV='/tmp/my-venv'
assert_env 'virtualenv still takes precedence over Conda' '(my-project) (my-venv) '
unset CONDA_DEFAULT_ENV

unset IN_NIX_SHELL
assert_env 'build marker still detects Nix' '(my-project) (my-venv) '
unset NIX_BUILD_TOP
assert_env 'leaving Nix preserves virtualenv' '(my-venv) '
unset VIRTUAL_ENV
assert_env 'leaving all environments hides all labels' ''
unset POLYGLOT_NIX_LABEL

CONDA_DEFAULT_ENV='base'
assert_env 'Conda outside Nix is unchanged' '(base) '
unset CONDA_DEFAULT_ENV
assert_env 'no stale labels' ''

printf 'Passed %s environment-label tests.\n' "$POLYGLOT_TEST_COUNT"

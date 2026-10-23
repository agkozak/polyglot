#!/bin/sh
# Synthetic regression tests for HOME-prefix handling in polyglot.sh.
set -eu

command -v bash >/dev/null 2>&1 || {
  printf '%s\n' 'bash is required for the isolated interactive-shell test' >&2
  exit 77
}
: "${TMPDIR:?Set TMPDIR to a task-local temporary directory}"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "$TMPDIR/polyglot-dirtrim.XXXXXX")
trap 'rm -rf "$test_root"' 0 HUP INT TERM

mkdir -p \
  "$test_root/home" \
  "$test_root/home-sibling/project" \
  "$test_root/home/alpha/beta/gamma" \
  "$test_root/zdotdir" \
  "$test_root/cache" \
  "$test_root/config"
: > "$test_root/bash-env"

HOME=$test_root/home
ZDOTDIR=$test_root/zdotdir
HISTFILE=$test_root/bash-history
BASH_ENV=$test_root/bash-env
ENV=$test_root/bash-env
XDG_CACHE_HOME=$test_root/cache
XDG_CONFIG_HOME=$test_root/config
TERM=dumb
POLYGLOT_UNAME=Linux
POLYGLOT_SCRIPT=$script_dir/polyglot.sh
GIT_CONFIG_GLOBAL=$test_root/gitconfig
GIT_CONFIG_NOSYSTEM=1
export HOME ZDOTDIR HISTFILE BASH_ENV ENV XDG_CACHE_HOME XDG_CONFIG_HOME
export TERM POLYGLOT_UNAME POLYGLOT_SCRIPT GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM

run_case() {
  expected=$1
  fixture=$2
  trim=$3

  actual=$(POLYGLOT_FIXTURE="$fixture" POLYGLOT_TRIM="$trim" \
    bash --noprofile --norc -i -c '
      . "$POLYGLOT_SCRIPT"
      cd "$POLYGLOT_FIXTURE" || exit 2
      _polyglot_prompt_dirtrim "$POLYGLOT_TRIM"
    ' 2>/dev/null)

  if [ "$actual" != "$expected" ]; then
    printf 'expected: <%s>\nactual:   <%s>\n' "$expected" "$actual" >&2
    return 1
  fi
}

run_case '~/.../beta/gamma' "$test_root/home/alpha/beta/gamma" 2
run_case '~/alpha/beta/gamma' "$test_root/home/alpha/beta/gamma" 0
run_case '~' "$test_root/home" 2
run_case '.../home-sibling/project' "$test_root/home-sibling/project" 2
run_case "$test_root/home-sibling/project" "$test_root/home-sibling/project" 0

printf '%s\n' 'dirtrim HOME-boundary tests passed'

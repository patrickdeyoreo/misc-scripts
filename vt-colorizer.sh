#!/usr/bin/env sh

## Set the virtual console colors
#

if test "$#" -ne 1; then
  printf 'usage: %s FILENAME\n' "${0##*/}"
  exit 2
fi


if ! test -e "$1" ; then
  printf 'error: %s: no such file or directory\n' "${1##*/}"
  exit 3

elif ! test -f "$1" ; then
  if test -d "$1" ; then
    printf 'error: %s: file is a directory\n' "${1##*/}"
  else
    printf 'error: %s: file is not a regular file\n' "${1##*/}"
  fi
  exit 4

elif ! test -r "$1"; then
  printf 'error: %s: read permission required\n' "${1##*/}"
  exit 5

elif ! test "${TERM}" = 'linux'; then
  printf 'error: %s: not a valid TERM (must be "linux")\n' "${TERM}"
  exit 6
fi >&2


printf '%b' $(
  sed -n 's/.*\*color\([0-9]\{1,\}\).*#\([0-9a-fA-F]\{6\}\).*/\1 \2/p' "$1" |
    awk '$1 < 16 {printf "\\e]P%X%s", $1m, $2}'
)

clear


exit 0

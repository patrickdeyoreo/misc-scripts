#!/usr/bin/env bash


[[ $# -eq 1 ]] || {
  printf 'usage: %s DESTINATION\n' "${0##*/}"
  exit 2
}

set -- "$(realpath "$1")"


mkdir -p "$1" || {
  printf 'error: %q: could not make directory\n' "$1"
  exit 3
}


[[ -w "$1" ]] || {
  printf 'error: %q: missing write permission\n' "$1"
  exit 4
}


trap '
printf '"'"'\n'"'"'
while true; do
  read -r -p '"'"'Do you really want to exit? (y/n): '"'"' &&
    case "${REPLY,,}" in
      y*)
        printf '"'"'Exiting...\n'"'"'
        exit 0
        ;;
      n*)
        printf '"'"'Press ENTER to resume...\n'"'"'
        break
        ;;
      *)
        continue
    esac
  printf '"'"'\n'"'"'
done
' SIGINT


printf 'Destination set to %q\n' "$1"


while read -r -p 'Target URL: '; true; do
  if [[ ${REPLY} ]]; then
    youtube-dl --ignore-errors --no-cache-dir --restrict-filenames \
      --output "$1/%(title)s-%(id)s.%(ext)s" "${REPLY}" 1> /dev/null 2>&1 &
  fi
done

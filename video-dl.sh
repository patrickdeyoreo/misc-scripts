#!/usr/bin/env bash

## video-dl.sh
##
## Patrick DeYoreo <pdeyoreo@gmail.com>
#
## video-dl.sh destination [options]
#
## environment:
##   URL_FD   : file descriptor from which URLs shall be read
##   YTDL_LOG : file to which youtube-dl output shall be written
#
## exit values:
##   0        : success (*see 'ytdl_log' for details)
##   1        : error setting up destination directory
##   2        : improper usage
##   127      : youtube-dl not found in PATH


## Check for proper usage
(( $# < 1 )) || {
  printf 'usage: %q [options] destination\n' "${0##*/}" 1>&2
  exit 2
}

## Check that youtube-dl is available
{ command -v youtube-dl && command -v realpath; } 1>/dev/null || {
  printf '%q: %q: command not found\n' "${0##*/}" "$_" 1>&2
  exit 127
}

## Resolve the destination path & shift positional params
set -- "${@:1:($#-1)}" "$(realpath "${!#}" && printf ':')"
set -- "${@:1:($#-1)}" "${!#%??}"

## Create the destination directory if it doesn't exist
[[ -d ${!#} ]] || mkdir -p "${!#}" || {
  printf '%q: %q: cannot create directory\n' "${0##*/}" "${!#}" 1>&2
  exit 1
}

## Check destination directory for sufficient permissions
[[ -r ${!#} && -w ${!#} && -x ${!#} ]] || {
  printf '%q: %q: permission denied\n' "${0##*/}" "${!#}" 1>&2
  exit 1
}

## Inform user that destination dir has been set successfully
printf '*> Destination set to %q\n' "${!#}"

## Change into the destination directory
cd -- "${!#}" || {
  printf '%q: %q: unable to enter directory\n' "${0##*/}" "${!#}" 1>&2
  return 1
}


## Trap to confirm exit upon receiving an interrupt
trap '
echo
while true; do
  read -e -r -p "Are you sure you want to exit? (y/n): " &&
    case ${REPLY^^} in
      Y*)
        printf "Exiting...\n"
        kill -s SIGINT "$$"
        ;;
      N*)
        printf "Press ENTER to resume...\n"
        break
        ;;
      *)
        continue
        ;;
    esac
  echo
done
' SIGINT


## Set URL_FD to an appropriate file descriptor
{ URL_FD="$((URL_FD))" && (( URL_FD >= 0 )) && { 0<&"$((URL_FD))"; }
} 2>/dev/null || exec {URL_FD}</dev/stdin

## Set YTDL_LOG to an appropriate file
{ YTDL_LOG="${YTDL_LOG:-/dev/stdout}" && 1>>"${YTDL_LOG}"
} 2>/dev/null || YTDL_LOG=/dev/null


## Read URLs from user and attempt to download any videos found
while true; do
  if read -er -p '>> URL: ' -u "${URL_FD:-0}" && [[ -n ${REPLY} ]]; then
    youtube-dl "${@:1:($#-1)}" "${REPLY}" 1>&"${YTDL_LOG_FD}" 2>&1 &
  fi
done {YTDL_LOG_FD}>"${YTDL_LOG:-/dev/null}"



## vim:et:ft=sh:sts=2:sw=2:ts=8:tw=80

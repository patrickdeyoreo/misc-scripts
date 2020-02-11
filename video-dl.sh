#!/usr/bin/env bash

# video-dl.sh
##
# Patrick DeYoreo <pdeyoreo@gmail.com>
#
# video-dl.sh [options] destination 
#
# environment:
#   YTDL_IN  : file descriptor from which URLs shall be read
#   YTDL_OUT : file descriptor on which to write YTDL output
#   YTDL_LOG : location at which to store download logs
#  
##
# exit values:
#   0        : success (*see 'ytdl_log' for details)
#   1        : error setting up destination directory
#   2        : improper usage
#   127      : youtube-dl not found in PATH


# Check for proper usage
(( $# )) || {
  printf 'usage: %q [options] destination\n' "${0##*/}" 1>&2
  exit 2
}

# Check that youtube-dl is available
{ command -v youtube-dl && command -v realpath; } 1>/dev/null || {
  printf '%q: %q: command not found\n' "${0##*/}" "$_" 1>&2
  exit 127
}

# Resolve the destination path & shift positional params
set -- "${@:1:($# - 1)}" "$(realpath "${!#}" && printf ':')"
set -- "${@:1:($# - 1)}" "${!#%??}"

# Create the destination directory if it doesn't exist
[[ -d ${!#} ]] || mkdir -p "${!#}" || {
  printf '%q: %q: cannot create directory\n' "${0##*/}" "${!#}" 1>&2
  exit 1
}

# Check destination directory for sufficient permissions
[[ -r ${!#} && -w ${!#} && -x ${!#} ]] || {
  printf '%q: %q: permission denied\n' "${0##*/}" "${!#}" 1>&2
  exit 1
}

# Inform user that destination dir has been set successfully
printf '*> Destination set to %q\n' "${!#}"

# Change into the destination directory
cd -- "${!#}" || {
  printf '%q: %q: unable to enter directory\n' "${0##*/}" "${!#}" 1>&2
  exit 1
}

# Trap to confirm exit upon receiving an interrupt
trap '
echo
while true; do
  read -r -p "Are you sure you want to exit? [Y/n]: " &&
    case ${REPLY^^} in
      Y*)
        trap SIGINT
        if [[ -n "$(jobs -pr)" ]]
        then
          printf "Waiting for download(s) to finish..."
          wait
          echo
        fi
        printf "Exiting..."
        kill -s SIGINT "$$"
        ;;
      N*)
        printf "Press ENTER to resume..."
        break
        ;;
      *)
        continue
        ;;
    esac
  echo
done
' SIGINT


# Set YTDL_IN to an appropriate file descriptor
YTDL_IN="$(( ${YTDL_IN:-0} ))"
if ! : 0<&"${YTDL_IN}"
then
  printf '%q: %q: bad file descriptor\n' "${0##*/}" "${YTDL_IN}"
  exit 1
fi 1>&2 2> /dev/null


# Set YTDL_OUT to an appropriate file
YTDL_OUT="$(( ${YTDL_OUT:-2} ))"
if ! : 1>&"${YTDL_OUT}"
then
  printf '%q: %q: bad file descriptor\n' "${0##*/}" "${YTDL_OUT}"
  exit 1
fi 1>&2 2> /dev/null


if [[ -n ${YTDL_LOG} ]]
then
  if ! mkdir -p "${YTDL_LOG%/*}"
  then
    printf '%q: %q: cannot create log directory\n' "${0##*/}" "${YTDL_OUT}"
    exit 1
  fi 1>&2 2>/dev/null
  trap '
  trap EXIT
  if [[ -f ${YTDL_LOG} && -w ${YTDL_LOG} ]]
  then
    echo 1>> "${YTDL_LOG}"
  fi
  ' EXIT
  # shellcheck disable=SC2183
  if ! { printf '%(%F %T)T: ' && echo "${0##*/}" "$@"; } 1>> "${YTDL_LOG}"
  then
    printf '%q: %q: cannot to write to log file\n' "${0##*/}" "${YTDL_OUT}"
    exit 1
  fi 1>&2 2>/dev/null
fi

# Read URLs from user and attempt to download any videos found
for (( dl = 0; 1; ++dl))
do
  if read -r -p 'URL: ' -u "${YTDL_IN}" && [[ -n ${REPLY} ]]
  then
    # shellcheck disable=SC2183
    if [[ -n ${YTDL_LOG} ]]
    then
      if
        printf '%(%F %T)T: Starting... '
        printf '[%04d]: %s\n' "$((dl))" "${REPLY}"
        youtube-dl "${@:1:($# - 1)}" -- "${REPLY}" 1>&"${YTDL_OUT}" 2>&1
      then
        printf '%(%F %T)T: Success. :) '
        printf '[%04d]: %s\n' "$((dl))" "${REPLY}"
      else
        printf '%(%F %T)T: Failure. :( '
        printf '[%04d]: %s\n' "$((dl))" "${REPLY}"
      fi 1>> "${YTDL_LOG}" &
    else
      { youtube-dl "${@:1:($# - 1)}" -- "${REPLY}" 1>&"${YTDL_OUT}" 2>&1
      } &
    fi
  fi
done

# vim:ft=sh

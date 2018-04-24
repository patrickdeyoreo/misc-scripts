#!/usr/bin/env bash


## Check for root privileges
if (( ${EUID} )); then
  printf '%s: error: must run as root\n' "${0##*/}" >&2
  exit 3
fi


## Parse options & check required arg
if (( !$# )) || [[ $1 = -* ]]; then
  case "$1" in
    ## Print helpful information
    -h|--help)
      printf 'usage: %s [-h|--help] [-l|--list] config\n' "${0##*/}"
      exit 0
      ;;

    ## Print available configurations
    -l|--list)
      if [[ -r /etc/openvpn/client/pia/ ]]; then
        ls -1 /etc/openvpn/client/pia/
        exit 0
      else
        printf 'error: cannot read /etc/openvpn/client/pia/\n' "${0##*/}" >&2
        exit 1
      fi
      ;;


    ## Invalid option - print usage spec
    *)
      printf 'usage: %s [-h|--help] [-l|--list] config\n' "${0##*/}" >&2
      exit 2
      ;;
  esac
fi


## Evalute filename & initiate connection
: "${1%${1##*/}}"
: "${_:-/etc/openvpn/client/pia/}${1##*/}"
openvpn --config "${_%.ovpn}.ovpn"

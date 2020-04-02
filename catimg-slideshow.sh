#!/usr/bin/env bash
#
# Play a slideshow with ASCII art


if [[ -n ${DEBUG:+/} ]]
then
  set "-${DEBUGOPTS:-xv}"
fi

NAME="${BASH_SOURCE[0]##*/}"
HELP="${NAME} [-h] [image|directory] ..."

checkdeps()
{
  if ! command -v catimg 1> /dev/null
  then
    printf '%s: %s: command not found\n' "$_" 1>&2
    exit 127
  fi
}

parseopts()
{
  local option

  while getopts ':h' "option"
  do
    case "${option}" in
      'h')
        printf '%s: usage: %s\n' "${NAME}" "${HELP}"
        exit 2
        ;;
      '?')
        printf '%s: -%s: invalid option\n' "${NAME}" "${OPTARG}" 1>&2
        exit 1
        ;;
      ':')
        printf '%s: -%s: option requires an argument\n' "${NAME}" "${OPTARG}"  1>&2
        exit 1
        ;;
    esac
  done
}

confirm()
{
  local REPLY=""

  while :
  do
    read -r -p "${1:-Confirm? }${2:-[Y/n] }" REPLY
    case "${REPLY^}" in
      'Y')
        return 0
        ;;
      'N')
        return 1
        ;;
    esac
  done
}

trapsigint()
{
  trap '
  trap SIGINT
  if confirm '\''Are you sure you want to exit? '\'' 1>&2
  then
    trap SIGINT
    echo '\''Exiting...'\''
    exit 130
  fi
  trapsigint
  ' SIGINT
}

sleep()
{
  if [[ ${#1} -eq 0 || ${1:-1} != *([[:digit:]])?(.+([[:digit:]])) ]]
  then
    printf '%s: %s: invalid argument to %s\n' "${NAME}" "$1" "${FUNCNAME[0]}" 1>&2
    return 1
  fi
  read -r -t "${1:-1}" _
  return 0
} 0<> <(:)

expandto()
{
  local -n aref

  if ! aref="$1" && [[ -v 'aref[@]' ]]
  then
    printf '%s: %s: invalid argument to %s\n' "${NAME}" "$1" "${FUNCNAME[0]}" 1>&2
    return 1
  fi
  shift
  while (( $# ))
  do
    if [[ -d $1 ]]
    then
      shopt -s nullglob
      expandto "${!aref}" "$1"/*
      shopt -u nullglob
    else
      aref+=( "$1" )
    fi
    shift
  done
  return 0
}

play()
{
  local i=0

  while :
  do
    catimg -w "${!i}"
    sleep 7
    (( ++i % $# ))
  done
}

main()
{
  OPTIND=1
  OPTARG=''
  
  local -a files=( )

  checkdeps
  parseopts "$@"
  shift "$((OPTIND - 1))"
  expandto 'files' "${@:-.}"
  play "${files[@]}"
}

trapsigint

main "$@"

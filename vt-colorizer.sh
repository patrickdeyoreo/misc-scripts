#!/usr/bin/env sh

## A script to set the terminal colors on a whim


## Show the usage info, or, if given an argument, the long help.
help() {
  case $# in (0) sed q ;; (*) cat ;; esac
} <<~eof~
usage: vt-colorizer.sh [-r] [file]
  Set the virtual console colors.

  If FILE is -, data is read from standard input.

  The -r option resets all colors to their original values.

  Color definitions follow a strict subset of the Xresources format spec.

  The following are examples of valid definitions:
    color1:  #CC221A
    color3 : #D79b1f
    *color7 :#9a971B
    *color15:#eeebea
~eof~


## Check non-option arguments.
ckargs() {

  test $# -eq 1 || {
    help
    return 1
  }

  test -e "$1" || {
    printf 'error: %s: No such file or directory\n' "$1"
    return 1
  }

  test -f "$1" || {
    printf 'error: %s: Not a regular file\n' "$1"
    return 1
  }

  test -r "$1" || {
    printf 'error: %s: Permission denied\n' "$1"
    return 1
  }

} 1>&2


## Load colors from a file.
apply() {

  sed -nE '
  /^[[:blank:]]*\*?color[[:digit:]]+[[:blank:]]*:[[:blank:]]*#[[:xdigit:]]{6}[[:blank:]]*$/!b
  s_.*color([[:digit:]]+).*#(..)(..)(..).*_tput initc \1 $(( 0x\2 * 1000 / 256 )) $(( 0x\3 * 1000 / 256 )) $(( 0x\4 * 1000 / 256 ))_ep
  ' "$1"

  clear

}


## Do the thing.
main() {
  for _; do
    case ${_::1} in
      -)
        case ${_#?} in
          -)
            shift
            break
            ;;
          r)
            tput oc
            return 0
            ;;
          h|-help)
            help ${_%-*}
            return 0
            ;;
          *)
            printf '%s: %s: unrecognized option\n' "${0##*/}" "$_" 1>&2
            return 2
            ;;
        esac
        shift
        ;;
      *)
        set -- "${@:2}" "$1"
        ;;
    esac
  done

  ckargs "$@" && apply "$@"

  return
}


## Run the beast.
main "$@"

exit

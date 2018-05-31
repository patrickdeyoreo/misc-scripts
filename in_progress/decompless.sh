#!/usr/bin/env bash


##############################################################################
## decompless.sh : Decompress a file and write it to stdout.
##############################################################################
##
## This may be used as a preprocessor for 'less' by adding the following line
## to your login profile (e.g. ~/.profile, ~/.bash_profile, etc.):
##
##   export LESSOPEN='||decompless.sh %s'
##
## NOTE: Sourcing this script will define a function 'decomp' in the current
## shell execution environment which can be used in place of this script to
## avoid the implicit subshell.
##
##############################################################################



##############################################################################
## Determine if this script is being sourced (i.e. using the "." builtin)
##############################################################################

unset -v sourced ## Get a variable to hold test result


## Is this zsh?
if test -n "${ZSH_EVAL_CONTEXT}"; then

  ## Check if the last element of ZSH_EVAL_CONTEXT is "file"
  test "${ZSH_EVAL_CONTEXT}" = "${ZSH_EVAL_CONTEXT%:file}"

  sourced=$? ## Save the test result



## Is this ksh? (ughh...)
elif test -n "${KSH_VERSION}"; then

  ## Prepend construction strings to positional params
  if set -- "$(set -- "$(dirname  -- "$0"; printf .)"
                cd -- "${1%?.}" && pwd -P; printf .)" \
            "$(basename -- "$0"          ; printf .)" \
            "$(set -- "$(dirname  -- "$0"; printf .)"
                cd -- "${1%?.}" && pwd -P; printf .)" \
            "$(basename -- "${.sh.file}" ; printf .)" \
            "$@"
  then ## Construct paths and compare them
    test "${1%?.}/${2%?.}" = "${3%?.}/${4%?.}"
    
    sourced=$? ## Save the test result

    shift 4 ## Restore positional parameters
  fi



## Is this bash?
if test -n "${BASH_VERSION}"; then

  ## Check if BASH_SOURCE matches the invoked shell or script
  test "${BASH_SOURCE}" = "$0"

  sourced=$? ## Save the test result



## Is this some other shell we recognize?
else ## sh, dash, ash
  case "${0:0:1}" in
    -) ## login shell
      case "${0:1}" in
        sh|dash|ash) sourced=1 ;; esac ;;
    *) ## just some shell
      case "${0##*/}" in
        sh|dash|ash) sourced=1 ;; esac ;;
  esac
fi



##############################################################################
## Definition of decomp()
##############################################################################


## Decompress a file and write it to stdout.
decomp() {

  case "${1##*.}" in
  
    tar)
     ;;
    tgz)
     ;;
    arc)
     ;;
    arj)
     ;;
    taz)
     ;;
    lha)
     ;;
    lz4)
     ;;
    lzh)
     ;;
    lzma)
     ;;
    tlz)
     ;;
    txz)
     ;;
    tzo)
     ;;
    t7z)
     ;;
    zip)
     ;;
    z)
     ;;
    Z)
     uncompress -c $1  >/tmp/less.$$  2>/dev/null
     if [ -s /tmp/less.$$ ]; then
       echo /tmp/less.$$
     else
       rm -f /tmp/less.$$
     fi
     ;;
  
    dz)
     ;;
    gz)
     ;;
    lrz)
     ;;
    lz)
     ;;
    lzo)
     ;;
    xz)
     ;;
    zst)
     ;;
    tzst)
     ;;
    bz2)
     ;;
    bz)
     ;;
    tbz)
     ;;
    tbz2)
     ;;
    tz)
     ;;
    deb)
     ;;
    rpm)
     ;;
    jar)
     ;;
    war)
     ;;
    ear)
     ;;
    sar)
     ;;
    rar)
     ;;
    alz)
     ;;
    ace)
     ;;
    zoo)
     ;;
    cpio)
     ;;
    7z)
     ;;
    rz)
     ;;
    cab)
     ;;
    wim)
     ;;
    swm)
     ;;
    dwm)
     ;;
    esd)
      ;;
    *)
      ;;
  esac
}



##############################################################################
## Exit appropriately with respect to how this script is being called.
##############################################################################


## Check the test result we computed earlier
case "$((${sourced:-(-1)}))" in
  1) ## sourced
    unset -v sourced
    return 0
    ;;
  0) ## called directly
    exit 0
    ;;
esac


## Test was inconclusive; just clean up and call it a day
unset -v sourced


##############################################################################
## End of Script
##############################################################################

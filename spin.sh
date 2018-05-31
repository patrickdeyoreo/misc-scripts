#!/usr/bin/env sh

## spin.sh : Display a spinning wheel to show progress
## 
## This file may be executed directly or sourced to define functions in the
## current shell that provide equivalent functionality without the subshell.
##
## ENVIRONMENT VARIABLES:
##  If N_SPINS__ is in the environment and contains a non-negative integer,
##  we will spin that many times. If it contains a negative integer,
##  we will run an infinite loop.
## 
##  If SPIN_SLEEP__ is in the environment, sleep(1) will be called with this
##  value between each redraw.
##  Note: permissible values may vary between implementations of sleep(1).
##
## THOUGHTS:
##  Define a spin function that accepts a callback?


## Define a single spin
spin_once() {
  for _ in '|' '\' '-' '/'; do

    printf '%s\b' "$_"

    if test -n "${SPIN_SLEEP__}"; then
      sleep "${SPIN_SLEEP__}"
    fi

  done
  return 0
}


## Define an infinite loop :P
spin_forever() {
  while :; do
    spin_once
  done
}


## Define a finite loop
spin_n() {
  while test "$1" -gt 0; do

    spin_once

    set -- "$(( $1 - 1 ))"

  done
}


## Define a spin function based on the afformentioned environment variables
spin() {
  if test -n "${N_SPINS__}"; then

    if test "${N_SPINS__}" -ge 0 2>/dev/null; then
      spin_n  "${N_SPINS__}"

    elif test "${N_SPINS__}" -lt 0 2>/dev/null; then
      spin_forever
    fi
  fi
}


## Now spin!
spin

## End

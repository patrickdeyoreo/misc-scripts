#!/usr/bin/env sh

## Load missing scancode-to-keycode translations for the Alienware17r3
## ** scancodes found via dmesg **

## If not called by root, exit.
test "$(id -u)" -ne 0 && {
  printf '%s: permission denied (must run as root)\n' "${0##*/}" >&2
  exit 1
}

## LHS
setkeycodes e011 135 ## MacroX MENU
setkeycodes e012 192 ## Macro1
setkeycodes e013 193 ## Macro2
setkeycodes e014 194 ## Macro3
setkeycodes e015 195 ## Macro4
setkeycodes e016 196 ## Macro5
                 
## RHS           
setkeycodes e017 197 ## Macro6
setkeycodes e018 198 ## Macro7
setkeycodes e01a 199 ## Macro8
setkeycodes e01b 200 ## Macro9

## Fn
setkeycodes e004 238 ## F2   WLAN
setkeycodes e03a 173 ## F8   REFRESH
setkeycodes e005 224 ## F9   BRIGHTNESSDOWN
setkeycodes e006 225 ## F10  BRIGHTNESSUP
setkeycodes e001 181 ## F11  NEW
setkeycodes 69   228 ## F12  KBDILLUMTOGGLE

#!/usr/bin/env sh

# A simple script to initialize ALSA sound devices.
#
# see alsactl_init(7)

exec command alsactl \
  --env ALSA_CONFIG_PATH="${ALSA_CONFIG_PATH:-/etc/alsa/alsactl.conf}"  \
  --initfile="${ALSACTL_INITFILE:-/usr/share/alsa/init/00main}"         \
  init

#!/bin/sh -u
#
# home-user-bind-generator
#
# > Generates mount units upon boot, defining bind mounts from the contents
#   of a user directory below /users into the equivalent location in /home.
#
# > Since /users and /home may not be mounted when this script runs,
#   the directories considered will be those found in /etc/skel.
#
#
# - TODO:
# * Abstraction to arbitrary users would require template generator


exec 2>/dev/null || exit 1

unset -v path prefix target unit || exit 1

target="$1/multi-user.target.wants"

prefix="$1/home-patrick"

mkdir -p "${target}" || exit 1

for path in /etc/skel/* /etc/skel/.* ; do
  case "${path##*/}" in
    .|..) continue ;;
  esac

  test -d "${path}" || continue
  test -L "${path}" && continue

  path="${path##*/}"
  unit="${prefix}-${path}.mount"

  ln -sf "${unit}" "${target}"

  cat <<EOF >| "${unit}"
[Unit]
RequiresMountsFor=/home
RequiresMountsFor=/users
ConditionPathIsDirectory=/home/patrick
ConditionPathIsDirectory=/users/patrick/${path}

[Mount]
What=/users/patrick/${path}
Where=/home/patrick/${path}
Options=rbind,nofail
Type=none

[Install]
WantedBy=multi-user.target
EOF

done

exit 0

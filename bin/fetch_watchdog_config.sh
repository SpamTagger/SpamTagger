#!/bin/bash
#
#   SpamTagger - Open Source Spam Filtering
#   Copyright (C) 2026 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#   This script will fetch the watchdog config
#
#   Usage:
#           fetch_watchdog_config.sh [-r]

# TODO: Disabled during transition to spamtagger
echo "Not currently supported for SpamTagger"
exit

usage() {
  cat <<EOF
usage: $0 options

This script will fetch watchdog modules and config

OPTIONS:
  -r   randomize start of the script, for automated process
EOF
}

randomize=false

while getopts ":r" OPTION; do
  case $OPTION in
  r)
    randomize=true
    ;;
  ?)
    usage
    exit
    ;;
  esac
done

CONFFILE=/etc/spamtagger.conf
SRCDIR=$(grep 'SRCDIR' $CONFFILE | cut -d ' ' -f3)
if [ "$SRCDIR" = "" ]; then
  SRCDIR="/usr/spamtagger"
fi
VARDIR=$(grep 'VARDIR' $CONFFILE | cut -d ' ' -f3)
if [ "$VARDIR" = "" ]; then
  VARDIR="/var/spamtagger"
fi

. $SRCDIR/lib/STUtils.sh
FILE_NAME=$(basename -- "$0")
FILE_NAME="${FILE_NAME%.*}"
ret=$(createLockFile "$FILE_NAME")
if [[ "$ret" -eq "1" ]]; then
  exit 0
fi

. $SRCDIR/lib/updates/download_files.sh

##
## Watchdog config updates
##

ret=$(downloadDatas "$SRCDIR/etc/watchdog/" "watchdog_config" $randomize "null" "" "noexit")
removeLockFile "$FILE_NAME"

exit 0

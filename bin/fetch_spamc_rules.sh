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
#   This script will fetch the actual spamassassin ruleset
#
#   Usage:
#           fetch_spamc_rules.sh [-r]

# TODO: Disabled during transition to spamtagger
echo "Not currently supported for SpamTagger"
exit

usage() {
  cat <<EOF
usage: $0 options

This script will fetch the current ruleset

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

. /usr/spamtagger/lib/STUtils.sh
FILE_NAME=$(basename -- "$0")
FILE_NAME="${FILE_NAME%.*}"
ret=$(createLockFile "$FILE_NAME")
if [[ "$ret" -eq "1" ]]; then
  exit 0
fi

. /usr/spamtagger/lib/updates/download_files.sh

##
## SpamAssassin rules update
##
ret=$(downloadDatas "/usr/spamtagger/share/spamassassin/" "spamc_rules" $randomize "null" "\|mailscanner.cf" "noexit")
if [[ "$ret" -eq "1" ]]; then
  /usr/spamtagger/etc/init.d/spamd stop >/dev/null 2>&1
  sleep 3
  /usr/spamtagger/etc/init.d/spamd start >/dev/null 2>&1
fi

removeLockFile "$FILE_NAME"

exit 0

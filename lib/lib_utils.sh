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
#   This lib permits to use useful function such as the LockFile process handling.

CONFFILE=/etc/spamtagger.conf
SRCDIR=$(grep 'SRCDIR' $CONFFILE | cut -d ' ' -f3)
if [ "$SRCDIR" = "" ]; then
  SRCDIR="/usr/spamtagger"
fi
VARDIR=$(grep 'VARDIR' $CONFFILE | cut -d ' ' -f3)
if [ "$VARDIR" = "" ]; then
  VARDIR="/var/spamtagger"
fi

LOCKFILEDIRECTORY=${VARDIR}/spool/tmp/

function createLockFile() {
  find ${LOCKFILEDIRECTORY} -type f -name "${1}" -mtime +1 -exec rm {} \;
  LOCKFILE=${LOCKFILEDIRECTORY}${1}
  if [ -f ${LOCKFILE} ]; then
    echo 1
  else
    echo $$ >${LOCKFILE}
    echo 0
  fi
}

function removeLockFile() {
  LOCKFILE=${LOCKFILEDIRECTORY}${1}
  rm -f ${LOCKFILE}
  echo $?
}

function replicaSynchronized() {
  replica_status=$(echo "SHOW REPLICA STATUS\G" | ${SRCDIR}/bin/st_mariadb -s)
  Last_IO_Errno=$(echo "${replica_status}" | awk '/Last_IO_Errno/{print $NF}')
  Last_SQL_Errno=$(echo "${replica_status}" | awk '/Last_SQL_Errno/{print $NF}')
  if [[ $Last_IO_Errno == "0" && $Last_SQL_Errno == "0" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

function isMaster() {
  is_source=$(grep 'ISSOURCE' $CONFFILE | cut -d ' ' -f3)
  if [[ "${is_source}" == "Y" || "${is_source}" == "y" ]]; then
    echo 1
  else
    echo 0
  fi
}

#!/bin/sh
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

search=$1
stage=$2

if [ "$stage" != "4" ]; then
  stage=1
fi

if [ "$search" = "" ]; then
  echo "Usage: move_queued_message.sh searchstring [stage]"
  exit 1
fi

SPOOLDIR="/var/spamtagger/spool/exim_stage$stage/input"
MSGLOGDIR="/var/spamtagger/spool/exim_stage$stage/msglog"
BACKUPDIR="/var/spamtagger/spool/exim_stage$stage/input_disabled"
BACKUPMSGLOGDIR="/var/spamtagger/spool/exim_stage$stage/msglog_disabled"

if [ ! -d $BACKUPDIR/$search ]; then
  mkdir -p $BACKUPDIR/$search
fi
if [ ! -d $BACKUPMSGLOGDIR/$search ]; then
  mkdir -p $BACKUPMSGLOGDIR/$search
fi

for i in $(grep $search $SPOOLDIR/* | cut -d':' -f1 | cut -d'-' -f1-3 | sort | uniq); do
  mv $i* $BACKUPDIR/$search/
  mv $MSGLOGDIR/$i $BACKUPMSGLOGDIR/$search/
done

echo "Messages from $search disabled !"
exit 0

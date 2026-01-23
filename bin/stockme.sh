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
#   This script will dump the apache config file with the configuration
#   settings found in the database.
#
#   Usage:
#           stock.sh

VARDIR=$(grep 'VARDIR' /etc/spamtagger.conf | cut -d ' ' -f3)
if [ "VARDIR" = "" ]; then
  VARDIR=/var/spamtagger
fi

for WHAT in spam ham; do
  BASEDIR=$VARDIR/spool/learningcenter/stock$WHAT/

  DIR=$BASEDIR/$(date '+%Y%m%d_%H')
  if [ ! -d $DIR ]; then
    mkdir -p $DIR
  fi
  mv $BASEDIR/tmp/* $DIR >/dev/null 2>&1
done

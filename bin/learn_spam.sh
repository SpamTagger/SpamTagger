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
#   This script will learn a message file or directory as a spam
#
#   Usage:
#           learn_spam.sh message_file/directory

SRCDIR=$(grep 'SRCDIR' /etc/spamtagger.conf | cut -d ' ' -f3)
if [ "SRCDIR" = "" ]; then
  SRCDIR=/var/spamtagger
fi

if [ "$1" = "" ]; then
  echo "usage: ./learn_spam.sh message_file|message_dir"
  exit 1
fi

if [ -f $1 ] || [ -d $1 ]; then
  sa-learn --spam -p $SRCDIR/etc/mailscanner/spam.assassin.prefs.conf $1
else
  echo "file/directory $1 is not useable"
  exit 1
fi

exit 0

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
#   This script will display the number of messages waiting on each of the 3
#   main spools which are:
#   Stage 1 for the incoming spool
#   Stage 2 for the filtering spool (antispam/antivirus processes)
#   Stage 4 for the outgoing spool
#
#   Usage:
#           check_spools.sh

EXIMBIN=/usr/bin/exim

echo -n "Stage 1:       "
$EXIMBIN -C /usr/spamtagger/etc/exim/exim_stage1.conf -bpc

echo -n "Stage 2:       "
TYPE=$(grep -e '^MTA\s*=\s*eximms' /usr/spamtagger/etc/mailscanner/MailScanner.conf)
if [ "$TYPE" = "" ]; then
  $EXIMBIN -C /usr/spamtagger/etc/exim/exim_stage2.conf -bpc
else
  ls /var/spamtagger/spool/exim_stage2/input/*.env 2>&1 | grep -v 'No such' | wc -l
fi

echo -n "Stage 4:       "
$EXIMBIN -C /usr/spamtagger/etc/exim/exim_stage4.conf -bpc

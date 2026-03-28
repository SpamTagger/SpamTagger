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
#   This script will fetch the bayesian packs (for spamc) to be learn
#
#   Usage:
#           CDN_fetch_bayes.sh

# TODO: Find a different way to sync bayes data
exit

LOGFILE="/var/spamtagger/log/spamtagger/downloadDatas.log"
SERVER="spamtaggerdl.alinto.net"
ROOTDIR="/bayes/"

. /usr/spamtagger/lib/STUtils.sh

function log {
  echo "["$(date "+%Y/%m/%d %H:%M:%S")"] $1" >>$LOGFILE
  if [ ! -z $2 ]; then
    removeLockFile "$FILE_NAME"
    exit $2
  fi
}

FILE_NAME=$(basename -- "$0")
FILE_NAME="${FILE_NAME%.*}"
ret=$(createLockFile "$FILE_NAME")
if [[ "$ret" -eq "1" ]]; then
  log "Lockfile exists for $FILE_NAME" 0
fi

if [ ! -d /var/spamtagger/spool/data_credentials/ ]; then
  mkdir -p /var/spamtagger/spool/data_credentials/
fi

# If the bayesian doesnt exist as a file, we remove its md5 associated file
# That way the re download will be forced
if [ ! -f /var/spamtagger/spool/spamassassin/bayes_toks ]; then
  rm -f /var/spamtagger/spool/spamassassin/bayes_toks.md5
fi
if [ ! -f /var/spamtagger/spool/bogofilter/database/wordlist.db ]; then
  rm -f /var/spamtagger/spool/bogofilter/database/wordlist.db.md5 >/dev/null 2>&1
fi

# Remove cached secrets
if [ -f /tmp/bayes_secrets ]; then
  rm -f /tmp/bayes_secrets >/dev/null 2>&1
fi

# Getting secrets
scp -q -o PasswordAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no mcscp@cvs.spamtagger.org:/data_credentials/bayes_secrets /tmp/bayes_secrets

OLD_SA_SECRET=''
OLD_BOGO_SECRET=''
if [ -f /var/spamtagger/spool/data_credentials/bayes_secrets ]; then
  OLD_SA_SECRET=$(grep spamassassin /var/spamtagger/spool/data_credentials/bayes_secrets | cut -d ' ' -f 2)
  OLD_BOGO_SECRET=$(grep bogofilter /var/spamtagger/spool/data_credentials/bayes_secrets | cut -d ' ' -f 2)
fi

# Enterprise Edition
if [ -f /tmp/bayes_secrets ]; then
  SA_SECRET=$(grep spamassassin /tmp/bayes_secrets | cut -d ' ' -f 2)
  BOGO_SECRET=$(grep bogofilter /tmp/bayes_secrets | cut -d ' ' -f 2)
  if [[ $OLD_SA_SECRET == $SA_SECRET ]] && [[ $OLD_BOGO_SECRET == $BOGO_SECRET ]]; then
    log "Enterprise data is already current" 0
  fi

  if [[ $OLD_SA_SECRET != $SA_SECRET ]]; then
    wget --no-check-certificate https://${SERVER}${ROOTDIR}/bayes_toks_$SA_SECRET -P /tmp/ >/dev/null 2>&1
    if [[ "$SA_SECRET" == "$(md5sum /tmp/bayes_toks_$SA_SECRET | cut -d ' ' -f 1)" ]]; then
      mv -f /tmp/bayes_toks_$SA_SECRET /var/spamtagger/spool/spamassassin/bayes_toks >/dev/null 2>&1
      log "Updated with latest Enterprise SA database"
    else
      log "New SA database does not match expected hash"
    fi
  fi

  if [[ $OLD_BOGO_SECRET != $BOGO_SECRET ]]; then
    wget --no-check-certificate https://${SERVER}${ROOTDIR}/wordlist.db_$BOGO_SECRET -P /tmp/ >/dev/null 2>&1
    if [[ "$BOGO_SECRET" == "$(md5sum /tmp/wordlist.db_$BOGO_SECRET | cut -d ' ' -f 1)" ]]; then
      mv -f /tmp/wordlist.db_$BOGO_SECRET /var/spamtagger/spool/spamassassin/wordlist.db >/dev/null 2>&1
      log "Updated with latest Enterprise BOGO database"
    else
      log "New BOGO database does not match expected hash"
    fi
  fi

  mv -f /tmp/bayes_secrets /var/spamtagger/spool/data_credentials/bayes_secrets
  rm /tmp/bayes_toks_* /tmp/wordlist.db_* 2>/dev/null
  rm /var/spamtagger/spool/spamassassin/bayes_toks_* /var/spamtagger/spool/spamassassin/wordlist.db_* 2>/dev/null

# Community Edition snapshots
else
  # Spamassassin
  rm -f /tmp/bayes_toks.md5 >/dev/null 2>&1
  wget --no-check-certificate https://${SERVER}${ROOTDIR}/bayes_toks.md5 -P /tmp/ >/dev/null 2>&1
  if [ ! -f /tmp/bayes_toks.md5 ]; then
    log "Could not retrieve bayes_toks.md5" 1
  fi
  NEW_MD5=$(cut -d' ' -f1 /tmp/bayes_toks.md5)
  if [ -f /var/spamtagger/spool/spamassassin/bayes_toks.md5 ]; then
    CURRENT_MD5=$(cut -d' ' -f1 /var/spamtagger/spool/spamassassin/bayes_toks.md5)
  else
    CURRENT_MD5=0
  fi

  if [[ "$CURRENT_MD5" != "$NEW_MD5" ]]; then
    wget --no-check-certificate https://${SERVER}${ROOTDIR}/bayes_toks -P /tmp/ >/dev/null 2>&1
    if [ ! -f /tmp/bayes_toks ]; then
      log "Could not retrieve bayes_toks" 1
    fi
    mv -f /tmp/bayes_toks /var/spamtagger/spool/spamassassin/ >/dev/null 2>&1
    mv -f /tmp/bayes_toks.md5 /var/spamtagger/spool/spamassassin/ >/dev/null 2>&1
    log "Updated with latest Community snapshot of bayes_toks"
  else
    log "No new bayes_toks (md5 didnt change)"
  fi

  # Bogofilter
  rm -f /tmp/wordlist.db.md5 >/dev/null 2>&1
  wget --no-check-certificate https://${SERVER}${ROOTDIR}/wordlist.db.md5 -P /tmp/ >/dev/null 2>&1
  if [ ! -f /tmp/wordlist.db.md5 ]; then
    log "Could not retrieve wordlist.db.md5" 1
  fi
  NEW_MD5=$(cut -d' ' -f1 /tmp/wordlist.db.md5)
  if [ -f /var/spamtagger/spool/bogofilter/database/wordlist.db.md5 ]; then
    CURRENT_MD5=$(cut -d' ' -f1 /var/spamtagger/spool/bogofilter/database/wordlist.db.md5)
  else
    CURRENT_MD5=0
  fi

  # If MD5 changed then the associated bayesians have to be updated
  if [[ "$CURRENT_MD5" != "$NEW_MD5" ]]; then
    wget --no-check-certificate https://${SERVER}${ROOTDIR}/wordlist.db -P /tmp/ >/dev/null 2>&1
    if [ ! -f /tmp/wordlist.db ]; then
      log "Could not retrieve wordlist.db" 1
    fi
    mv -f /tmp/wordlist.db /var/spamtagger/spool/bogofilter/database/ >/dev/null 2>&1
    mv -f /tmp/wordlist.db.md5 /var/spamtagger/spool/bogofilter/database/ >/dev/null 2>&1
    log "Updated with latest Community snapshot of wordlist.db"
  else
    log "No new wordlist.db (md5 didnt change)"
  fi

  rm -f /tmp/bayes_toks.md5 >/dev/null 2>&1
  rm -f /tmp/wordlist.db.md5 >/dev/null 2>&1
fi

removeLockFile "$FILE_NAME"

exit 0

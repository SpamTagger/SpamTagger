#!/bin/bash

# remove bayes_seen if > 15M
SIZE=$(ls -l /var/spamtagger/spool/spamassassin/bayes_seen | cut -d' ' -f5)
if [ $SIZE -gt 15000000 ]; then
  rm /var/spamtagger/spool/spamassassin/bayes_seen
fi
# remove sa and clamav temp files
if [ -d /dev/shm ]; then
  rm -rf /dev/shm/.spam* >/dev/null 2>&1
  rm -rf /dev/shm/clamav* >/dev/null 2>&1
  rm -rf /dev/shm/* >/dev/null 2>&1
fi

#sa-learn -p /usr/spamtagger/etc/mailscanner/spam.assassin.prefs.conf --force-expire 2>&1
chown -R spamtagger:spamtagger /var/spamtagger/spool/spamassassin

# purge stock
find /var/spamtagger/spool/learningcenter/stockham/ -ctime +3 -exec rm -rf \{\} \; >/dev/null 2>&1
find /var/spamtagger/spool/learningcenter/stockspam/ -ctime +3 -exec rm -rf \{\} \; >/dev/null 2>&1

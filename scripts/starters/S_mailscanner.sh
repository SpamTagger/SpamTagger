#!/bin/bash

DELAY=4

export PATH=$PATH:/sbin:/usr/sbin

PREVPROC=$(pgrep -f mailscanner/bin/MailScanner)
if [ ! "$PREVPROC" = "" ]; then
  echo -n "ALREADYRUNNING"
  exit
fi

/opt/spamtagger/etc/init.d/mailscanner start 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f MailScanner)
if [ "$PREVPROC" = "" ]; then
  echo -n "ERRORSTARTING"
  exit
else
  echo -n "SUCCESSFULL"
fi

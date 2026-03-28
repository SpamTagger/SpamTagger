#!/bin/bash

DELAY=2

export PATH=$PATH:/sbin:/usr/sbin

PREVPROC=$(pgrep -f /etc/apache/httpd.conf)
if [ ! "$PREVPROC" = "" ]; then
  echo -n "ALREADYRUNNING"
  exit
fi

/usr/spamtagger/etc/init.d/apache start 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f /etc/apache/httpd.conf)
if [ "$PREVPROC" = "" ]; then
  echo -n "ERRORSTARTING"
  exit
else
  echo -n "SUCCESSFULL"
fi

#!/bin/bash

DELAY=2

export PATH=$PATH:/sbin:/usr/sbin

/usr/spamtagger/etc/init.d/exim_stage2 stop 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f /etc/exim/exim_stage2)
if [ ! "$PREVPROC" = "" ]; then
  echo -n "FAILED"
  exit
else
  echo -n "SUCCESSFULL"
fi

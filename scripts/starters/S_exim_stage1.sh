#!/bin/bash

DELAY=2

export PATH=$PATH:/sbin:/usr/sbin

PREVPROC=$(pgrep -f /etc/exim/exim_stage1)
if [ ! "$PREVPROC" = "" ]; then
  echo -n "ALREADYRUNNING"
  exit
fi

/opt/spamtagger/etc/init.d/exim_stage1 start 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f /etc/exim/exim_stage1)
if [ "$PREVPROC" = "" ]; then
  echo -n "ERRORSTARTING"
  exit
else
  echo -n "SUCCESSFULL"
fi

#!/bin/bash

DELAY=2

export PATH=$PATH:/sbin:/usr/sbin

PREVPROC=$(pgrep -f /libexec/dccifd)
if [ ! "$PREVPROC" = "" ]; then
  echo -n "ALREADYRUNNING"
  exit
fi

/opt/spamtagger/etc/init.d/rcDCC start 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f /libexec/dccifd)
if [ "$PREVPROC" = "" ]; then
  echo -n "ERRORSTARTING"
  exit
else
  echo -n "SUCCESSFULL"
fi

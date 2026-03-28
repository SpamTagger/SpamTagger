#!/bin/bash

DELAY=2

export PATH=$PATH:/sbin:/usr/sbin

/usr/spamtagger/etc/init.d/mariadb_source stop 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f /etc/mariadb/my_source.cnf)
if [ ! "$PREVPROC" = "" ]; then
  echo -n "FAILED"
  exit
else
  echo -n "SUCCESSFULL"
fi

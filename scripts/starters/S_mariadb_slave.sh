#!/bin/bash

DELAY=4

export PATH=$PATH:/sbin:/usr/sbin

PREVPROC=$(pgrep -f /etc/mariadb/my_replica.cnf)
if [ ! "$PREVPROC" = "" ]; then
  echo -n "ALREADYRUNNING"
  exit
fi

/usr/spamtagger/etc/init.d/mariadb_replica start 2>&1 >/dev/null
sleep $DELAY
PREVPROC=$(pgrep -f /etc/mariadb/my_replica.cnf)
if [ "$PREVPROC" = "" ]; then
  echo -n "ERRORSTARTING"
  exit
else
  echo -n "SUCCESSFULL"
fi

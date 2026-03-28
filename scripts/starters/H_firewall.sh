#!/bin/bash

DELAY=2

export PATH=$PATH:/sbin:/usr/sbin

/usr/spamtagger/etc/init.d/firewall stop 2>&1 >/dev/null
sleep $DELAY
echo -n "SUCCESSFULL"

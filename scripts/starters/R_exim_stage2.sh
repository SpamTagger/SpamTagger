#!/bin/bash

export PATH=$PATH:/sbin:/usr/sbin

/opt/spamtagger/etc/init.d/exim_stage2 restart 2>&1 >/dev/null
if test $? -ne 0; then
  echo -n "FAILED"
  exit 1
fi
echo -n "SUCCESSFULL"
exit 0

#!/bin/bash

MYSPAMTAGGERPWD=$(grep -e '^MYSPAMTAGGERPWD' /etc/spamtagger.conf | cut -d ' ' -f3)
HTTPPROXY=$(grep -e '^HTTPPROXY' /etc/spamtagger.conf | cut -d ' ' -f3)
export http_proxy=$HTTPPROXY

####################
## razor discover ##
####################

su spamtagger -c "razor-admin -discover"

####################
## pyzor discover ##
####################

su spamtagger -c "pyzor discover" 2>&1 >/dev/null

if [ ! -d /var/spamtagger/.pyzor ]; then
  mkdir /var/spamtagger/.pyzor
fi
#echo "82.94.255.100:24441" > /var/spamtagger/.pyzor/servers
chown -R spamtagger:spamtagger /var/spamtagger/.pyzor

if [ ! -d /root/.pyzor ]; then
  mkdir /root/.pyzor
fi
cp /var/spamtagger/.pyzor/servers /root/.pyzor/servers
#echo "82.94.255.100:24441" > /root/.pyzor/servers

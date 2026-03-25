#!/bin/bash

MYSPAMTAGGERPWD=$(grep 'MYSPAMTAGGERPWD' /etc/spamtagger.conf | cut -d ' ' -f3)
HTTPPROXY=$(grep -e '^HTTPPROXY' /etc/spamtagger.conf | cut -d ' ' -f3)
export http_proxy=$HTTPPROXY

. /opt/spamtagger/lib/lib_utils.sh
FILE_NAME=$(basename -- "$0")
FILE_NAME="${FILE_NAME%.*}"
ret=$(createLockFile "$FILE_NAME")
if [[ "$ret" -eq "1" ]]; then
  exit 0
fi

if [ ! -f /var/spamtagger/log/clamav/freshclam.log ]; then
  /bin/touch /var/spamtagger/log/clamav/freshclam.log
fi
/bin/chown clamav:clamav /var/spamtagger/log/clamav/freshclam.log

if [ -e /var/spamtagger/run/clamd.disabled ] && [ -e /var/spamtagger/run/clamspamd.disabled ]; then
  echo "Abandoning update because both services are disabled" >>/var/spamtagger/log/clamav/freshclam.log
  exit 0
fi

if [ ! -f /opt/spamtagger/etc/clamav/freshclam.conf ]; then
  /opt/spamtagger/bin/dump_clamav_config.pl
fi

echo "["$(date "+%Y-%m-%d %H:%M:%S")"] Starting ClamAV update..." >>/var/spamtagger/log/clamav/freshclam.log
/usr/bin/freshclam --user=clamav --config-file=/opt/spamtagger/etc/clamav/freshclam.conf --daemon-notify=/opt/spamtagger/etc/clamav/clamd.conf >>/var/spamtagger/log/clamav/freshclam.log 2>&1

RET=$?

if [ $RET -le 1 ]; then
  echo "OK"
else
  if [[ $RET -eq 52 || $RET -eq 58 || $RET -eq 59 || $RET -eq 62 ]]; then
    echo "Network error, not able to download data now,retrying later..."
    echo "["$(date "+%Y-%m-%d %H:%M:%S")"] Network error, not able to download data now,retrying later..." >>/var/spamtagger/log/clamav/freshclam.log
  else
    echo "Error.. trying from scratch..."
    echo "["$(date "+%Y-%m-%d %H:%M:%S")"] Error.. trying from scratch..." >>/var/spamtagger/log/clamav/freshclam.log
    echo -n " Purging current data... "
    echo "["$(date "+%Y-%m-%d %H:%M:%S")"] Purging current data... " >>/var/spamtagger/log/clamav/freshclam.log
    rm -rf /var/spamtagger/spool/clamav/* &>/dev/null
    echo "done"
    echo -n " Retrying download... "
    echo "["$(date "+%Y-%m-%d %H:%M:%S")"] Retrying download... " >>/var/spamtagger/log/clamav/freshclam.log
    /usr/bin/freshclam --user=clamav --config-file=/opt/spamtagger/etc/clamav/freshclam.conf --daemon-notify=/opt/spamtagger/etc/clamav/clamd.conf --quiet

    RET2=$?
    if [ $RET2 -le 1 ]; then
      echo "OK"
      echo "["$(date "+%Y-%m-%d %H:%M:%S")"] OK" >>/var/spamtagger/log/clamav/freshclam.log
    else
      echo "NOTOK $RET2"
      echo "["$(date "+%Y-%m-%d %H:%M:%S")"] NOTOK $RET2" >>/var/spamtagger/log/clamav/freshclam.log
    fi
  fi
fi

if [ -e /etc/spamtagger/clamav-unofficial-sigs ]; then
  if [[ "$(shasum /etc/spamtagger/clamav-unofficial-sigs | cut -d' ' -f1)" == "69c58585c04b136a3694b9546b77bcc414b52b12" ]]; then
    if [ ! -e /var/spamtagger/spool/clamav/unofficial-sigs ]; then
      echo "Installing Unofficial Signatures..." >>/var/spamtagger/log/clamav/freshclam.log
      mkdir /var/spamtagger/spool/clamav/unofficial-sigs
      /bin/chown clamav:clamav -R /var/spamtagger/spool/clamav/unofficial-sigs
      /opt/spamtagger/scripts/cron/clamav-unofficial-sigs.sh --force >>/var/spamtagger/log/clamav/freshclam.log
    else
      echo "Updating Unofficial Signatures..." >>/var/spamtagger/log/clamav/freshclam.log
      /opt/spamtagger/scripts/cron/clamav-unofficial-sigs.sh --update >>/var/spamtagger/log/clamav/freshclam.log
    fi
  else
    echo "/etc/spamtagger/clamav-unofficial-sigs exists but does not contain the correct information. Please enter exactly:"
    echo "I have read the terms of use at: https://sanesecurity.com/usage/linux-scripts/"
  fi
fi

echo "["$(date "+%Y-%m-%d %H:%M:%S")"] Done." >>/var/spamtagger/log/clamav/freshclam.log
removeLockFile "$FILE_NAME"

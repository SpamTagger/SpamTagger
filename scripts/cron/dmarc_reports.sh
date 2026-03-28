#!/bin/bash

DOIT=$(echo "SELECT dmarc_enable_reports FROM mta_config WHERE stage=1;" | /usr/spamtagger/bin/st_mariadb -s st_config | grep -v 'dmarc_enable_reports')
if [ "$DOIT" != "1" ]; then
  exit 0
fi
echo "select hostname, password from source;" | /usr/spamtagger/bin/st_mariadb -s st_config | grep -v 'password' | tr -t '[:blank:]' ':' >/var/tmp/source.conf
MHOST=$(cat /var/tmp/source.conf | cut -d':' -f1)
MPASS=$(cat /var/tmp/source.conf | cut -d':' -f2)
ISSOURCE=$(grep 'ISSOURCE' /etc/spamtagger.conf | cut -d ' ' -f3)

SYSADMIN=$(echo "SELECT summary_from FROM system_conf;" | /usr/spamtagger/bin/st_mariadb -s st_config | grep '\@')
if [ "$SYSADMIN" != "" ]; then
  SYSADMIN=" --report-email $SYSADMIN"
fi

if [ "$ISSOURCE" == "Y" ] || [ "$ISSOURCE" == "y" ]; then
  echo -n "Generating DMARC reports..."
  if [ ! -d /tmp/dmarc_reports ]; then
    mkdir /tmp/dmarc_reports
  fi
  CURDIR=$(pwd)
  cd /tmp/dmarc_reports
  echo "*****************************" >>/var/spamtagger/log/spamtagger/dmarc_reporting.log
  /opt/exim4/sbin/opendmarc-reports --dbhost=$MHOST --dbport=3306 --dbname=dmarc_reporting --dbuser=spamtagger --dbpasswd=$MPASS --smtp-port 587 --verbose --verbose --interval=86400 $SYSADMIN 2>>/var/spamtagger/log/spamtagger/dmarc_reporting.log
  echo "**********" >>/var/spamtagger/log/spamtagger/dmarc_reporting.log
  echo "Expiring database..." >>/var/spamtagger/log/spamtagger/dmarc_reporting.log
  /opt/exim4/sbin/opendmarc-expire --dbhost=$MHOST --dbport=3306 --dbname=dmarc_reporting --dbuser=spamtagger --dbpasswd=$MPASS --expire=180 --verbose 2 &>>/var/spamtagger/log/spamtagger/dmarc_reporting.log
  echo "Done expiring." >>/var/spamtagger/log/spamtagger/dmarc_reporting.log
  echo "*****************************" >>/var/spamtagger/log/spamtagger/dmarc_reporting.log
  cd $CURDIR
  echo "done."
fi

exit 0

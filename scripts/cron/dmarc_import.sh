#!/bin/bash

echo "select hostname, password from source;" | /usr/spamtagger/bin/st_mariadb -s st_config | grep -v 'password' | tr -t '[:blank:]' ':' >/var/tmp/source.conf
MHOST=$(cat /var/tmp/source.conf | cut -d':' -f1)
MPASS=$(cat /var/tmp/source.conf | cut -d':' -f2)

if [ -s /var/spamtagger/spool/tmp/exim/dmarc.history ]; then

  echo -n "Importing to source database at $MHOST..."
  /opt/exim4/sbin/opendmarc-import --dbhost=$MHOST --dbport=3306 --dbname=dmarc_reporting --dbuser=spamtagger --dbpasswd=$MPASS </var/spamtagger/spool/tmp/exim/dmarc.history
  /bin/rm /var/spamtagger/spool/tmp/exim/dmarc.history
  /bin/touch /var/spamtagger/spool/tmp/exim/dmarc.history
  /bin/chown spamtagger:spamtagger /var/spamtagger/spool/tmp/exim/dmarc.history
  echo "done."
fi

exit 0

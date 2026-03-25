#!/bin/bash

if [ "$USEDEBS" = "Y" ]; then
  echo -n " installing mailscanner binaries packages..."
  aptitude install st-mailscanner &>/dev/null
  echo "done."
else

  echo "########!!!!!!!!!!!!##########"
  echo " to install mailscanner.. "
  echo " 1) install tnef (in /usr/tnef)"
  echo " 2) unpack mailscanner archive (the one in perl-tar)"
  echo " 3) copy it to /opt/MailScanner"
  echo " 4) apply MailScanner.patch to /opt/MailScanner"
  echo " 5) cp SpamTaggerPrefs.pm and MailWatch.pm in new mailscanner, and apply MailWatch.patch"
  echo " 6) /root/compare_ms_configs/compare.pl and compare_language.pl"
  echo " ..bye bye..."
  exit

  BACK=$(pwd)

  cd /opt/spamtagger/install/src
  tar -xvzf tnef.tar.gz
  cd tnef-1.2.3.1
  ./configure
  make
  make install
  cd /opt/spamtagger/install/src
  rm -rf tnef-1.2.3.1

  cd /opt/spamtagger/install/src
  tar -xvzf Mailscanner.tar.gz
  cd MailScanner-install-4.45.4

  ./install.sh

  cd /opt/spamtagger

  if [ -d mailscanner_old ]; then
    rm -rf mailscanner_old
  fi
  if [ -d mailscanner ]; then
    mv mailscanner mailscanner_old
  fi

  mv /opt/MailScanner-4.45.4 mailscanner

  SD=$(echo /opt/spamtagger | perl -pi -e 's/\//\\\//g')
  perl -pi -e "s/\/opt\/MailScanner/$SD\/mailscanner/g" /opt/spamtagger/mailscanner/bin/check_mailscanner
  perl -pi -e "s/config=\S+/config=$SD\/etc\/mailscanner\/MailScanner.conf/g" /opt/spamtagger/mailscanner/bin/check_mailscanner
  perl -pi -e "s/\/opt\/MailScanner/$SD\/mailscanner/g" /opt/spamtagger/mailscanner/bin/MailScanner
  perl -pi -e "s/SCANNERSCONF=\S+/SCANNERSCONF=$SD\/etc\/mailscanner\/virus.scanners.conf/g" /opt/spamtagger/mailscanner/bin/update_virus_scanners

  cp /opt/spamtagger/install/src/MailScanner_Custom/SpamTaggerPrefs.pm /opt/spamtagger/mailscanner/lib/MailScanner/CustomFunctions/
  cp /opt/spamtagger/install/src/MailScanner_Custom/clamav-wrapper /opt/spamtagger/mailscanner/lib/
  cp /opt/spamtagger/install/src/MailScanner_Custom/etrust-wrapper /opt/spamtagger/mailscanner/lib/
  cp /opt/spamtagger/install/src/MailScanner_Custom/etrust-autoupdate /opt/spamtagger/mailscanner/lib/
  cp /opt/spamtagger/install/src/MailScanner_Custom/MailWatch.pm /opt/spamtagger/mailscanner/lib/MailScanner/
  cp /opt/spamtagger/install/src/MailScanner_Custom/MailWatch.patch /opt/spamtagger/mailscanner/lib/MailScanner/
  cd /opt/spamtagger/mailscanner/lib/MailScanner/
  patch -p0 <MailWatch.patch

  /opt/spamtagger/bin/dump_mailscanner_config.pl

  cd $BACK
fi

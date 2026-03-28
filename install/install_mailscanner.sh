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

  cd /usr/spamtagger/install/src
  tar -xvzf tnef.tar.gz
  cd tnef-1.2.3.1
  ./configure
  make
  make install
  cd /usr/spamtagger/install/src
  rm -rf tnef-1.2.3.1

  cd /usr/spamtagger/install/src
  tar -xvzf Mailscanner.tar.gz
  cd MailScanner-install-4.45.4

  ./install.sh

  cd /usr/spamtagger

  if [ -d mailscanner_old ]; then
    rm -rf mailscanner_old
  fi
  if [ -d mailscanner ]; then
    mv mailscanner mailscanner_old
  fi

  mv /opt/MailScanner-4.45.4 mailscanner

  SD=$(echo /usr/spamtagger | perl -pi -e 's/\//\\\//g')
  perl -pi -e "s/\/opt\/MailScanner/$SD\/mailscanner/g" /usr/spamtagger/mailscanner/bin/check_mailscanner
  perl -pi -e "s/config=\S+/config=$SD\/etc\/mailscanner\/MailScanner.conf/g" /usr/spamtagger/mailscanner/bin/check_mailscanner
  perl -pi -e "s/\/opt\/MailScanner/$SD\/mailscanner/g" /usr/spamtagger/mailscanner/bin/MailScanner
  perl -pi -e "s/SCANNERSCONF=\S+/SCANNERSCONF=$SD\/etc\/mailscanner\/virus.scanners.conf/g" /usr/spamtagger/mailscanner/bin/update_virus_scanners

  cp /usr/spamtagger/install/src/MailScanner_Custom/SpamTaggerPrefs.pm /usr/spamtagger/mailscanner/lib/MailScanner/CustomFunctions/
  cp /usr/spamtagger/install/src/MailScanner_Custom/clamav-wrapper /usr/spamtagger/mailscanner/lib/
  cp /usr/spamtagger/install/src/MailScanner_Custom/etrust-wrapper /usr/spamtagger/mailscanner/lib/
  cp /usr/spamtagger/install/src/MailScanner_Custom/etrust-autoupdate /usr/spamtagger/mailscanner/lib/
  cp /usr/spamtagger/install/src/MailScanner_Custom/MailWatch.pm /usr/spamtagger/mailscanner/lib/MailScanner/
  cp /usr/spamtagger/install/src/MailScanner_Custom/MailWatch.patch /usr/spamtagger/mailscanner/lib/MailScanner/
  cd /usr/spamtagger/mailscanner/lib/MailScanner/
  patch -p0 <MailWatch.patch

  /usr/spamtagger/bin/dump_mailscanner_config.pl

  cd $BACK
fi

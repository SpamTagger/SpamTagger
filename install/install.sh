#!/usr/bin/env bash
# vim: set ts=2 sw=2 expandtab :
#
# SpamTagger Application Configuration
#
# This script should be run after all necessary packages are installed on any OS
# base.
#
# It should include all application configuration which can be done before the
# final packaging of an appliance image. Any steps which should be done upon
# first-boot of an appliance (eg. generation of unique certificate/keys/user
# configurations) should be included in scripts/installer/installer.pl which is
# run automatically at the end of this script if not run from CI, or upon first
# boot of an appliance.

setterm --foreground blue
echo -n "# Creating bare spamtagger configuration file..."
setterm --foreground default

touch /etc/spamtagger.conf
if [[ $? -ne 0 ]]; then
  echo -e "\b\b\b x "
  exit 1
else
  echo -e "\b\b\b * "
fi

setterm --foreground blue
echo -n "# Check or create spool dirs..."
setterm --foreground default

# TODO: merge this script here
/usr/spamtagger/bin/ST_create_vars.sh &>/dev/null

setterm --foreground blue
echo -n "# Disabling default services..."
setterm --foreground default

for service in exim rsyslog; do
  RET="$(systemctl is-active service >/dev/null)"
  if [[ $RET == 0 ]]; then
    systemctl disable --now $service >/dev/null
  fi
done
echo -e "\b\b\b * "

setterm --foreground blue
echo -n "# Initialize and enable SpamTagger services..."
setterm --foreground default


for i in $(find /usr/spamtagger/scripts/systemd); do
  basename=$(echo $i | sed -r 's#/usr/spamtagger/scripts/systemd##')
  if [[ -d $i ]]; then
    [[ -e /usr/lib/systemd/system/$basename ]] || mkdir -p /usr/lib/systemd/system/$basename
  else
    ln -s $i /usr/lib/systemd/system/$basename
  fi
done
fangfrisch -c /usr/spamtagger/etc/fangfrisch.conf initdb

for service in rsyslog; do
  RET="$(systemctl is-active service >/dev/null)"
  if [[ $RET != 0 ]]; then
    systemctl enable $service
  fi
done
echo -e "\b\b\b * "

### building MailScanner
# TODO: Package and host with APT repo
# Should just be added to trixie.apt when available.

### install starter baysian packs
# TODO: Download these during build time. This will allow them to be relatively recent while costing me nothing in hosting costs.

setterm --foreground blue
echo -n "# Configuring Cron..."
setterm --foreground default

echo -n " - Installing scheduled jobs...                        "
echo "0,15,30,45 * * * *  /usr/spamtagger/scripts/cron/spamtagger_cron.pl > /dev/null" >/etc/cron.d/spamtagger
echo "0-59/5 * * * * /usr/spamtagger/bin/collect_rrd_stats.pl > /dev/null" >>/etc/cron.d/spamtagger
# prevent syslog from rotating mailscanner log files
#perl -pi -e 's/`syslogd-listfiles`/`syslogd-listfiles -s mailscanner`/' /etc/cron.daily/sysklogd 2>&1 >>$LOGFILE
#perl -pi -e 's/`syslogd-listfiles --weekly`/`syslogd-listfiles --weekly -s mailscanner`/' /etc/cron.weekly/sysklogd 2>&1 >>$LOGFILE
systemctl restart cron 2>&1 /dev/null
echo -e "\b\b\b * "

setterm --foreground blue
echo -n "# Updating .bashrc..."
setterm --foreground default

mkdir -p /var/spamtagger/state
chown spamtagger:spamtagger /var/spamtagger/state
echo 'source /usr/spamtagger/.bashrc' >> /etc/bash.bashrc
echo -e "\b\b\b * "

if [ -z $CI ]; then
  setterm --foreground blue
  echo -n "# Detected manual installation, automatically installing.bashrc..."
  setterm --foreground default

  /usr/spamtagger/scripts/installer/installer.pl
fi

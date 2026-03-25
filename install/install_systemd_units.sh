#!/bin/bash

for i in $(find /opt/spamtagger/scripts/systemd/* -maxdepth 0); do
  if [[ -e "/usr/lib/systemd/system/$(basename $i)" ]]; then
    echo $i already exists at /usr/lib/systemd/system/$(basename $i)
    rm -rf /usr/lib/systemd/system/$(basename $i)
  fi
  ln -s $i /usr/lib/systemd/system/$(basename $i)
done

systemctl daemon-reload

systemctl enable clamav-freshclam.timer
systemctl enable clamspamd-fangfrisch.timer

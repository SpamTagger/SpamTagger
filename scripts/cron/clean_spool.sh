#!/usr/bin/env bash

## clean exim garbage
for exim in 1 2 4; do
  cd /var/spamtagger/spool/exim_stage$exim/input/
  for dir in $(find . -type d); do
    if [ "$dir" != '.' ]; then cd $dir; fi

    for i in $(ls *-D 2>/dev/null); do
      j=$(echo $i | cut -d'-' -f-3)
      if [ ! -f $j-H ]; then rm $i >/dev/null 2>&1; fi
    done
    for i in $(ls *-H 2>/dev/null); do
      j=$(echo $i | cut -d'-' -f-3)
      if [ ! -f $j-D ]; then rm $i >/dev/null 2>&1; fi
    done
    for i in $(ls *-J 2>/dev/null); do
      j=$(echo $i | cut -d'-' -f-3)
      if [ ! -f $j-H ]; then rm $i >/dev/null 2>&1; fi
    done
    for i in $(ls *-K 2>/dev/null); do
      j=$(echo $i | cut -d'-' -f-3)
      if [ ! -f $j-H ]; then rm $i >/dev/null 2>&1; fi
    done
    for i in $(ls *-T 2>/dev/null); do
      j=$(echo $i | cut -d'-' -f-3)
      if [ ! -f $j-H ]; then rm $i >/dev/null 2>&1; fi
    done

    if [ "$dir" != '.' ]; then cd ..; fi
  done
done

## clean spamstore
cd /var/spamtagger/spool/exim_stage4/spamstore/
for f in $(ls *.env 2>/dev/null | cut -d'.' -f-1); do
  if [ ! -f $f.msg ]; then
    rm $f.env
  fi
done
rm *.tmp 2>/dev/null

## clean tmp dir
if [ -d /var/spamtagger/spool/tmp ]; then
  cd /var/spamtagger/spool/tmp
  rm -rf clamav-* .spamassassin* >/dev/null 2>&1
fi
if [ -d /var/spamtagger/spool/tmp/mailscanner/spamassassin ]; then
  cd /var/spamtagger/spool/tmp/mailscanner/spamassassin
  rm -rf MailScanner.* >/dev/null 2>&1
fi
find /var/spamtagger/spool/exim_stage1/scan -type f -mtime +30 -delete
find /var/spamtagger/spool/exim_stage1/scan -type d -empty -delete
cd /var/spamtagger/spool/tmp

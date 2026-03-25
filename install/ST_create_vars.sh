#!/bin/bash

ETCDIR=/etc/spamtagger
DEFAULTUID=spamtagger
DEFAULTGID=spamtagger

#########################################################
# check if dir exists and create it if not
# params:
#   dir = directory (fullpath)
#   uid = user owner
#   gid = group owner
#
# no uid/gid check for now...

function check_dir {
  dir=$1
  if [ "$2" = "" ]; then
    uid=$DEFAULTUID
  else
    uid=$2
  fi
  if [ "$3" = "" ]; then
    gid=$DEFAULTGID
  else
    gid=$3
  fi

  if [ ! -d $dir ]; then
    echo "directory: $dir does not exists !"
    mkdir $dir
    echo "directory: $dir created"
  else
    echo "directory $dir ok"
  fi

  chown $uid:$gid $dir
}
#########################################################

################
## BEGIN SCRIPT
################

check_dir $ETCDIR
check_dir /var/spamtagger

####
# create top-level dirs

check_dir /var/spamtagger/log
check_dir /var/spamtagger/spool
check_dir /var/spamtagger/run
check_dir $ETCDIR/apache

####
# create exim dirs

check_dir /var/spamtagger/log/exim_stage1 spamtagger
check_dir /var/spamtagger/log/exim_stage2 spamtagger
check_dir /var/spamtagger/log/exim_stage4 spamtagger

check_dir /var/spamtagger/spool/exim_stage1
check_dir /var/spamtagger/spool/exim_stage1/input
check_dir /var/spamtagger/spool/exim_stage2
check_dir /var/spamtagger/spool/exim_stage2/input
check_dir /var/spamtagger/spool/exim_stage4
check_dir /var/spamtagger/spool/exim_stage4/input
check_dir /var/spamtagger/spool/exim_stage4/paniclog
check_dir /var/spamtagger/spool/exim_stage4/spamstore

####
# create mariadb dirs

check_dir /var/spamtagger/log/mariadb_source mysql spamtagger
check_dir /var/spamtagger/log/mariadb_replica mysql spamtagger
chmod -R g+ws /var/spamtagger/log/mariadb_source
chmod -R g+ws /var/spamtagger/log/mariadb_replica

check_dir /var/spamtagger/spool/mariadb_source mysql spamtagger
check_dir /var/spamtagger/spool/mariadb_replica mysql spamtagger

check_dir /var/spamtagger/run/mariadb_source mysql spamtagger
check_dir /var/spamtagger/run/mariadb_replica mysql spamtagger

####
# create spamtagger dirs

check_dir /var/spamtagger/spool/tmp
check_dir /var/spamtagger/spool/mailscanner/
check_dir /var/spamtagger/spool/mailscanner/incoming
check_dir /var/spamtagger/spool/mailscanner/quarantine
check_dir /var/spamtagger/spool/mailscanner/users

check_dir /var/spamtagger/log/mailscanner spamtagger

check_dir /var/spamtagger/spam

check_dir /var/spamtagger/spool/spamassassin

####
# create apache dirs

check_dir /var/spamtagger/log/apache spamtagger
check_dir /var/spamtagger/www
check_dir /var/spamtagger/www/mrtg
check_dir /var/spamtagger/www/stats

####
# create spamtagger dirs

check_dir /var/spamtagger/log/spamtagger
check_dir /var/spamtagger/spool/spamtagger
check_dir /var/spamtagger/spool/spamtagger/prefs
check_dir /var/spamtagger/spool/spamtagger/counts
check_dir /var/spamtagger/spool/spamtagger/stats
check_dir /var/spamtagger/spool/spamtagger/scripts
check_dir /var/spamtagger/spool/spamtagger/addresses
check_dir /var/spamtagger/spool/rrdtools
check_dir /var/spamtagger/spool/bogofilter
check_dir /var/spamtagger/spool/bogofilter/database
check_dir /var/spamtagger/spool/bogofilter/updates
check_dir /var/spamtagger/spool/learningcenter
check_dir /var/spamtagger/spool/learningcenter/stockspam
check_dir /var/spamtagger/spool/learningcenter/stockham
check_dir /var/spamtagger/spool/learningcenter/stockrandom
check_dir /var/spamtagger/spool/learningcenter/stockrandom/spam
check_dir /var/spamtagger/spool/learningcenter/stockrandom/spam/cur
check_dir /var/spamtagger/spool/learningcenter/stockrandom/ham
check_dir /var/spamtagger/spool/learningcenter/stockrandom/ham/cur
check_dir /var/spamtagger/spool/watchdog
check_dir /var/spamtagger/run/spamtagger
check_dir /var/spamtagger/run/spamtagger/log_search
check_dir /var/spamtagger/run/spamtagger/stats_search

####
# create clamav dirs

check_dir /var/spamtagger/log/clamav clamav clamav
check_dir /var/spamtagger/spool/clamav clamav clamav
check_dir /var/spamtagger/run/clamav clamav clamav
check_dir /var/spamtagger/spool/clamspam clamav clamav

####
# create dcc dirs

check_dir /var/spamtagger/spool/dcc dcc dcc
check_dir /var/spamtagger/run/dcc dcc dcc

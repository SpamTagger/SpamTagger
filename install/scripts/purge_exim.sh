#!/bin/bash

rm -rf /var/spamtagger/log/exim_stage1/*
rm -rf /var/spamtagger/log/exim_stage2/*
rm -rf /var/spamtagger/log/exim_stage4/*

rm /var/spamtagger/run/exim*

rm -rf /var/spamtagger/spool/exim_stage1/db/*
rm -rf /var/spamtagger/spool/exim_stage1/input/*
rm -rf /var/spamtagger/spool/exim_stage1/msglog/*

rm -rf /var/spamtagger/spool/exim_stage2/db/*
rm -rf /var/spamtagger/spool/exim_stage2/input/*
rm -rf /var/spamtagger/spool/exim_stage2/msglog/*

rm -rf /var/spamtagger/spool/exim_stage4/db/*
rm -rf /var/spamtagger/spool/exim_stage4/input/*
rm -rf /var/spamtagger/spool/exim_stage4/msglog/*

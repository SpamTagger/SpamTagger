#!/usr/bin/env perl
#
#   SpamTagger - Open Source Spam Filtering
#   Copyright (C) 2026 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#   This script will dump the clamav configuration file with the configuration
#   settings found in the database.
#
#   Usage:
#       dump_clamspam_config.pl

use v5.40;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

our ($HTTPPROXY);
BEGIN {
  if ($0 =~ m/(\S*)\/\S+.pl$/) {
    my $path = $1."/../lib";
    unshift (@INC, $path);
  }
  require ReadConfig;
  my $conf = ReadConfig::get_instance();
  $HTTPPROXY = $conf->get_option('HTTPPROXY');
  unshift(@INC, "/opt/spamtagger/lib");
}

use STUtils qw( open_as rmrf );

my $lasterror;

my $uid = getpwnam( 'clamav' );
my $gid = getgrnam( 'spamtagger' );

# Create necessary dirs/files if they don't exist
foreach my $dir (
  "/var/spamtagger/log/clamspamd",
  "/var/spamtagger/run/clamspamd",
  "/var/spamtagger/spool/clamspamd",
) {
  mkdir($dir) unless (-d $dir);
  chown($uid, $gid, $dir);
}

foreach my $file (
  glob("/var/spamtagger/log/clamspamd/*"),
  glob("/var/spamtagger/run/clamspamd/*"),
  glob("/var/spamtagger/spool/clamspamd/*"),
) {
  print("Taking ownership of $file\n");
  chown($uid, $gid, $file);
}

# Configure sudoer permissions if they are not already
mkdir '/etc/sudoers.d' unless (-d '/etc/sudoers.d');
if (open(my $fh, '>', '/etc/sudoers.d/clamav')) {
  print $fh "
User_Alias  CLAMAV = clamav
Cmnd_Alias  CLAMBIN = /usr/sbin/clamd

CLAMAV    * = (ROOT) NOPASSWD: CLAMBIN
";
}

# Dump configuration
dump_file("clamspamd.conf");

#############################
sub dump_file($file)
{
  my $template_file = "/opt/spamtagger/etc/clamav/${file}";
  my $target_file = "/var/spamtagger/etc/clamav/${file}";
  my $custom = 0;
  if (-e "/etc/spamtagger/etc/clamav/${file}") {
    ($custom, $template_file) = (1, "/etc/spamtagger/etc/clamav/${file}");
  }

  my ($TEMPLATE, $TARGET);
  confess "Cannot open $template_file" unless ( $TEMPLATE = ${open_as($template_file,'<',0o664,'clamav:clamav')} );
  confess "Cannot open $template_file" unless ( $TARGET = ${open_as($target_file,'>',0o664,'clamav:clamav')} );

  my $proxy_server = "";
  my $proxy_port = "";
  if ($HTTPPROXY) {
    if ($HTTPPROXY =~ m/http\:\/\/(\S+)\:(\d+)/) {
      $proxy_server = $1;
      $proxy_port = $2;
    }
  }

  while(my $line = <$TEMPLATE>) {
    if ($proxy_server =~ m/\S+/) {
      $line =~ s/\#HTTPProxyServer __HTTPPROXY__/HTTPProxyServer $proxy_server/g;
      $line =~ s/\#HTTPProxyPort __HTTPPROXYPORT__/HTTPProxyPort $proxy_port/g;
    }

    print $TARGET $line;
  }
  close $TEMPLATE;

  # Additional user options
  foreach my $options ( 'clamspamd' ) {
    if ($file eq "${options}.conf" && -e "/etc/spamtagger/clamav/${options}.options") {
      confess "Cannot open /etc/spamtagger/clamav/${options}.options" unless ( $TEMPLATE = ${open_as("/etc/spamtagger/clamav/${options}.options",'<')} );
      while(my $line = <$TEMPLATE>) {
        print $TARGET $line;
      }
    }
  }

  close $TARGET;

  return 1;
}

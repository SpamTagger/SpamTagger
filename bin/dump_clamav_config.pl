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
#       dump_clamav_config.pl

use v5.40;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

use lib "/usr/spamtagger/lib";
use ReadConfig;
my $conf = ReadConfig::get_instance();
my $HTTPPROXY = $conf->get_option('HTTPPROXY');

use STUtils qw( open_as rmrf );
use ConfigTemplate;

my $lasterror;

my $uid = getpwnam( 'clamav' );
my $gid = getgrnam( 'spamtagger' );

# Create necessary dirs/files if they don't exist
foreach my $dir (
  "/usr/spamtagger/etc/clamav",
  "/var/spamtagger/log/clamav",
  "/var/spamtagger/run/clamav",
  "/var/spamtagger/spool/clamav",
) {
  mkdir($dir) unless (-d $dir);
  chown($uid, $gid, $dir);
}

foreach my $file (
  glob("/var/spamtagger/log/clamav/*"),
  glob("/var/spamtagger/run/clamav/*"),
  glob("/var/spamtagger/spool/clamav/*"),
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
dump_file("etc/clamav/clamd.conf");
dump_file("etc/clamav/freshclam.conf");
dump_file("etc/clamav/fangfrisch.conf");

#############################
sub dump_file($file)
{
  my $template = ConfigTemplate->new($file);

  my %replacements;
  if ($file eq "etc/clamav/freshclam.conf") {
    $template->set_condition('HTTPPROXY', 0);
    my $proxy_server = "";
    my $proxy_port = "";
    if ($HTTPPROXY) {
      if ($HTTPPROXY =~ m/((?:https?|socks(?:4a?|5h?))\:\/\/[^:]+)(\:\d+)?/) {
        $proxy_server = $1;
        $proxy_port = $2 || '';
      }
    }

    # TODO: Use Validator function to match hostname
    if ($proxy_server =~ m/\S+/) {
      $template->set_condition('HTTPPROXY', 1);
      $replacements{__HTTPPROXY__} = $proxy_server;
      $replacements{__HTTPPROXYPORT__} = $proxy_port;
      # TODO: We should add the ability to use authenticated proxies, but this
      # would require global testing with a real proxy.
      #HTTPProxyUsername __HTTPPROXYUSER__
      #HTTPProxyPassword __HTTPPROXYPASSWORD__
    } else {
      print STDERR "No valid HTTPPROXY server '$HTTPPROXY', disabling...\n";
    }
  }

  # Add Fangfrisch Add-ons
  if ($file eq "etc/clamav/fangfrisch.conf") {
    $replacements{__MALWAREPATROL_ENABLED__} = 'no';
    $replacements{__MALWAREPATROL_RECEIPT__} = '';
    $replacements{__SANESECURITY_ENABLED__}  = 'no';
    $replacements{__SANESECURITY_PREFIX__}   = '';
    $replacements{__SECURITEINFO_ENABLED__}  = 'no';
    $replacements{__SECURITEINFO_CUSTID__}   = '';
  }

  $template->set_replacements(\%replacements);
  return $template->dump_file();
}

# Potential future options

#ArchiveMaxFileSize 15M
#ArchiveMaxRecursion 9
#ArchiveMaxFiles 1500
#ArchiveMaxCompressionRatio 300

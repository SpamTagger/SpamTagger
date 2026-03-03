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

our ($HTTPPROXY);
BEGIN {
  if ($0 =~ m/(\S*)\/\S+.pl$/) {
    my $path = $1."/../lib";
    unshift (@INC, $path);
  }
  require ReadConfig;
  my $conf = ReadConfig::get_instance();
  $HTTPPROXY = $conf->get_option('HTTPPROXY');
  unshift(@INC, "/usr/spamtagger/lib");
}

use STUtils qw( open_as rmrf );

my $lasterror;

my $uid = getpwnam( 'clamav' );
my $gid = getgrnam( 'spamtagger' );

# Create necessary dirs/files if they don't exist
foreach my $dir (
  "/etc/clamav",
  "/usr/spamtagger/etc/clamav",
  "/var/spamtagger/log/clamav",
  "/var/spamtagger/run/clamav",
  "/var/spamtagger/spool/clamav",
) {
  mkdir($dir) unless (-d $dir);
  chown($uid, $gid, $dir);
}

foreach my $file (
  glob("/usr/spamtagger/etc/clamav/*"),
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

symlink('/usr/spamtagger/etc/apparmor', '/etc/apparmor.d/clamav') unless (-e '/etc/apparmor.d/clamav');

# Reload AppArmor rules
`apparmor_parser -r /usr/spamtagger/etc/apparmor.d/clamav` if ( -d '/sys/kernel/security/apparmor' );

# SystemD auth causes timeouts
`sed -iP '/^session.*pam_systemd.so/d' /etc/pam.d/common-session`;

# Dump configuration
dump_file("clamd.conf");
dump_file("freshclam.conf");
dump_file("fangfrisch.conf");

#############################
sub dump_file($file)
{
  my $template_file = "/usr/spamtagger/etc/clamav/${file}";
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
  foreach my $options ( 'clamd', 'clamspamd', 'freshclam' ) {
    if ($file eq "${options}.conf" && -e "/etc/spamtagger/clamav/${options}.options") {
      confess "Cannot open /etc/spamtagger/clamav/${options}.options" unless ( $TEMPLATE = ${open_as("/etc/spamtagger/clamav/${options}.options",'<')} );
      while(my $line = <$TEMPLATE>) {
        print $TARGET $line;
      }
    }
  }

  # Add Fangfrisch Add-ons
  if ($file eq "fangfrisch.conf") {
    my %addons = (
      # Product name  => Regex for acceptable settings
      'malwarepatrol' => qr/^\s*(\[malwarepatrol\]|enabled *= *(yes|no)|receipt *= *\S+)$/,
      'sanesecurity'  => qr/^\s*(\[sanesecurity\]|enabled *= *(yes|no)|prefix *= *\S+)$/,
      'securiteinfo'  => qr/^\s*(\[securiteinfo\]|enabled *= *(yes|no)|customer_id *= *\w+)$/
    );
    foreach my $prod (keys(%addons)) {
      if ( -e "/etc/spamtagger/add-ons/clamav/${prod}.toml") {
        confess "Cannot open /etc/spamtagger/add-ons/clamav/${prod}.toml" unless ( $TEMPLATE = ${open_as("/etc/spamtagger/add-ons/clamav/${prod}.toml",'<')} );
        my $addon = '';
        while(my $line = <$TEMPLATE>) {
          next if ($line =~ /^\s*$/);
          if ($line !~ $addons{$prod}) {
            print STDERR "Invalid line for $prod config: $line, disabling.\n";
            $addon = '';
            last;
          }
        }
        print $TARGET $addon."\n";
      }
    }
  }

  close $TARGET;

  return 1;
}

# Potential future options

#ArchiveMaxFileSize 15M
#ArchiveMaxRecursion 9
#ArchiveMaxFiles 1500
#ArchiveMaxCompressionRatio 300

#HTTPProxyServer __HTTPPROXY__
#HTTPProxyPort __HTTPPROXYPORT__
#HTTPProxyUsername __HTTPPROXYUSER__
#HTTPProxyPassword __HTTPPROXYPASSWORD__

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
#   This script will dump the freshclam configuration file with the configuration
#   settings found in the database.
#
#   Usage:
#       dump_freshclam_config.pl [--agree-to-unofficial|--remove_unofficial]

use v5.40;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

use lib '/usr/spamtagger/lib';
use STUtils qw( open_as );
use File::Touch qw( touch );

my $unofficial = shift || 0;
my $lasterror;

my $uid = getpwnam( 'clamav' );
my $gid = getgrnam( 'spamtagger' );
my $conf = '/etc/clamav';

if (-e $conf && ! -s $conf) {
  unlink(glob("$conf/*"), $conf);
}
symlink("/usr/spamtagger/".$conf, $conf) unless (-l $conf);

# Create necessary dirs/files if they don't exist
foreach my $dir (
  "/usr/spamtagger/etc/clamav/",
  "/var/spamtagger/log/clamav/",
  "/var/spamtagger/run/clamav/",
  "/var/spamtagger/spool/clamspam/",
  "/var/spamtagger/spool/clamav/",
) {
  mkdir($dir) unless (-d $dir);
  chown($uid, $gid, $dir);
}

foreach my $file (
  glob("/usr/spamtagger/etc/clamav/*"),
  "/var/spamtagger/log/clamav/freshclam.log",
) {
  touch($file) unless (-e $file);
}

foreach my $file (
  "/var/spamtagger/log/clamav",
  glob("/var/spamtagger/log/clamav/*"),
  "/var/spamtagger/run/clamav",
  glob("/var/spamtagger/run/clamav/*"),
  "/var/spamtagger/spool/clamspam",
  glob("/var/spamtagger/spool/clamspam/*"),
  "/var/spamtagger/spool/clamav",
  glob("/var/spamtagger/spool/clamav/*"),
) {
  chown($uid, $gid, $file);
}

# Configure sudoer permissions if they are not already
mkdir '/etc/sudoers.d' unless (-d '/etc/sudoers.d');
if (open(my $fh, '>', '/etc/sudoers.d/clamav')) {
  print $fh "
User_Alias  CLAMAV = spamtagger 
Cmnd_Alias  CLAMBIN = /usr/sbin/clamd

CLAMAV    * = (ROOT) NOPASSWD: CLAMBIN
";
}

symlink('/usr/spamtagger/etc/apparmor', '/etc/apparmor.d/spamtagger') unless (-e '/etc/apparmor.d/spamtagger');

# Reload AppArmor rules
`apparmor_parser -r /usr/spamtagger/etc/apparmor.d/clamav` if ( -d '/sys/kernel/security/apparmor' );

# SystemD auth causes timeouts
`sed -iP '/^session.*pam_systemd.so/d' /etc/pam.d/common-session`;

# Dump configuration
dump_file("freshclam.conf");

print STDERR "To enable ClamAV Unofficial Signatures, either run with '--agree-to-unofficial' or add *exactly* the following to /var/spamtagger/spool/spamtagger/clamav-unofficial-sigs:
I have read the terms of use at: https://sanesecurity.com/usage/linux-scripts/\n" unless update_unofficial($unofficial);

sub remove_unofficial() {
  my @dest = glob("/var/spamtagger/spool/clamav/*");
  foreach my $d (@dest) {
    my $s = $d;
    $s =~ s/clamav/clamav\/unofficial-sigs/;
    if (-l $d && $s eq readlink($d)) {
      unlink($d);
      unlink($s);
    }
  }
  rmdir("/var/spamtagger/spool/clamav/unofficial-sigs/");
  return 0;
}

sub update_unofficial($unofficial) {
  return remove_unofficial() if ($unofficial eq '--remove-unofficial');
  if ($unofficial eq '--agree-to-unofficial') {
    print "By running with '--agree-to-unofficial', you are confirming that you have read and agree to the terms at https://sanesecurity.com/usage/linux-scripts/\n";
    if (open(my $fh, '>', "/var/spamtagger/spool/spamtagger/clamav-unofficial-sigs")) {
      print $fh "I have read the terms of use at: https://sanesecurity.com/usage/linux-scripts/";
      close $fh;
    }
  } else {
    return remove_unofficial() unless (-e "/var/spamtagger/spool/spamtagger/clamav-unofficial-sigs");
    require Digest::SHA;
    my $sha = Digest::SHA->new();
    $sha->addfile("/var/spamtagger/spool/spamtagger/clamav-unofficial-sigs");
    return remove_unofficial unless ($sha->hexdigest() eq "69c58585c04b136a3694b9546b77bcc414b52b12");
  }

  # First time install
  if (! -d "/var/spamtagger/spool/clamav/unofficial-sigs") {
    mkdir("/var/spamtagger/spool/clamav/unofficial-sigs");
    `/usr/spamtagger/scripts/cron/clamav-unofficial-sigs.sh`;
  }

  # Create links if missing
  foreach my $s (glob("/var/spamtagger/spool/clamav/unofficial-sigs/*")) {
    my $d = $s;
    $d =~ s/unofficial-sigs\///;
    symlink($s, $d) unless (-e $d);
  }
  return 1;
}

#############################
sub dump_file($file)
{
  my $template_file = "/usr/spamtagger/etc/clamav/".$file."_template";
  my $target_file = "/usr/spamtagger/etc/clamav/".$file;

  my ($TEMPLATE, $TARGET);
  confess "Cannot open $template_file" unless ( $TEMPLATE = ${open_as($template_file,'<',0o664,'clamav:clamav')} );
  confess "Cannot open $template_file" unless ( $TARGET = ${open_as($target_file,'>',0o664,'clamav:clamav')} );

  while(<$TEMPLATE>) {
    print $TARGET $_;
  }

  close $TEMPLATE;
  close $TARGET;

  return 1;
}

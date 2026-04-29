#!/usr/bin/env perl
#
#   SpamTagger - Open Source Spam Filtering
#   Copyright (C) 2026 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; e/ither version 3 of the License, or
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
#   This script will dump the exim configuration file from the configuration
#   setting found in the database.
#

use v5.40;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

use TOML qw( from_toml );
use JSON::XS qw( decode_json );
use LWP::UserAgent;
use File::Path qw( mkpath );
use Config;

our $ua = LWP::UserAgent->new();

our $EXT_DIR = "/var/lib/extensions";
mkpath $EXT_DIR unless (-d $EXT_DIR);

our ($ARCH) = $Config{'myarchname'} =~ m/(.*)-linux$/;
$ARCH = "amd64" if $ARCH eq "x86_64";

our $DEB_VERSION;
confess "/etc/os-release not found"  unless (-e "/etc/os-release");
my $FH;
confess "Failed to open /etc/os-release\n" unless (open($FH, '<', "/etc/os-release"));
while (<$FH>) {
  if ($_ =~ m/VERSION_CODENAME=(\w+)/) {
    $DEB_VERSION = $1;
    last;
  }
}
close($FH);

sub usage() {
  print("usage: $0 [-s|--status|-i|-install|-r|--remove|-u|--update|-a|-auto] <package>

-s --status       List supported extensions, installed status and versions. Package name option to
                  list only details for that extension.
-i --install      Fetch and merge the named system extension. Requires package name argument.
-r --remove       Fetch and merge the named system extension. Requires package name argument.
-u --update       Check for newer versions of already installed extensions and update them.
-a --auto         Automatically install all recommened and requested extensions. This includes any
                  which match detected hardware, or which have a configuration flag set.
");
  exit(1);
}

sub get_installed_version($name) {
  my ($file, $FH) = ( "/var/lib/extensions/$name.manifest" );
  return undef unless (-e $file);
  confess "Failed to open manifest $file\n" unless (open($FH, '<', $file));
  while (<$FH>) {
    if ($_ =~ m/PACKAGE_VERSION=(\d.*)/) {
      my $v = $1;
      close($FH);
      return $v;
    }
  }
  close($FH);
  return undef
}

sub link_from_github($ext, $repo, $type) {
  my $releases = "https://api.github.com/repos/${repo}/releases";
  my $json = $ua->get($releases) || confess("Failed to fetch $releases: $!\n");
  chomp($json);
  my $tags = decode_json($json->content()) || confess("Failed to parse: $json\n");
  foreach my $file (@{$tags->[0]->{assets}}) {
    if ($file->{name} eq "${ext}_${DEB_VERSION}_${ARCH}.${type}") {
      return $file->{browser_download_url};
    }
  }
  confess("Unable to find $type URL for $repo release\n");
}

sub download_latest($exts, $name) {
  my $url = $exts->{$name}->{url} or confess("Did not find repo URL for $name\n");
  
  if ($url =~ m#https://github.com/(.*)#) {
    my $squashfs = link_from_github($name, $1, 'squashfs');
    $ua->get($squashfs, ':content_file' => "${EXT_DIR}/$name.raw") || confess("Could not fetch $squashfs: $!\n");
  } elsif ($url =~ m#(:?https?://)?([^/]+)/.*#) {
    confess("Fetching extensions from $1 not currently supported\n");
  } else {
    confess("Extension repo URL missing or invalid\n");
  }
}

sub get_available_version($exts, $name) {
  my $url = $exts->{$name}->{url} or confess("Did not find repo URL for $name\n");
  
  if ($url =~ m#https://github.com/(.*)#) {
    my $manifest = link_from_github($name, $1, 'manifest');
    my $data = $ua->get($manifest)->content() || confess("Could not fetch $manifest: $!\n");
    foreach my $line (split(/\n/, $data)) {
      if ($line =~ m/PACKAGE_VERSION=(\d.*)/) {
	return $1;
      }
    }
  } elsif ($url =~ m#(:?https?://)?([^/]+)/.*#) {
    confess("Fetching extensions from $1 not currently supported\n");
  } else {
    confess("Extension repo URL missing or invalid\n");
  }
}

sub get_status() {
  my $manifest = "/usr/spamtagger/etc/sysext.toml";
  my ($FH, $toml, $exts);
  confess "Missing Extensions manifest $manifest\n" unless (-e $manifest);
  confess "Failed to open manifest $manifest\n" unless (open($FH, '<', $manifest));
  $toml .= $_ while (<$FH>);
  close($FH);
  confess "Failed to parse TOML from $manifest\n" unless ($exts = from_toml($toml));
  my $json = `systemd-sysext status --json=short`;
  chomp($json);
  my $ret = decode_json($json) || confess("Could not parse current systemd-sysext status: $json\n");
  my @active;
  foreach my $hierarchy (@{$ret}) {
    push(@active, @{$hierarchy->{extensions}}) unless ($hierarchy->{extensions} eq "none");
  }
  $json = `systemd-sysext list --json=short`;
  chomp($json);
  $ret = decode_json($json) || confess("Could not parse current systemd-sysext status: $json\n");
  print "$_->{name}\n" foreach (@{$ret});
  my @installed = map { $_->{name} } (@{$ret});
  foreach my $ext (keys(%{$exts})) {
    if (-e "/var/lib/extensions/${ext}.raw") {
      if (scalar(@active) == 0) {
        if (scalar(@installed) && scalar(grep(/^${ext}/, @installed))) {
          $exts->{$ext}->{status} = "inactive";
        } else {
          $exts->{$ext}->{status} = "corrupted";
        }
      } elsif (grep(/^${ext}$/, @active)) {
        $exts->{$ext}->{status} = "active";
      } else {
        if (scalar(@installed) && scalar(grep(/^${ext}/, @installed))) {
          $exts->{$ext}->{status} = "inactive";
        } else {
          $exts->{$ext}->{status} = "corrupted";
        }
      }
    } else {
      $exts->{$ext}->{status} = "not installed";
    }
    $exts->{$ext}->{version} = get_installed_version($ext);
    $exts->{$ext}->{available} = get_available_version($exts, $ext);
  }
  return $exts;
}

our $exts = get_status();
sub print_status($ext = undef) {
  printf("+%s+%s+%s+%s+%s+\n", "-"x22, "-"x16, "-"x14, "-"x14, "-"x14);
  printf("| %-20s | %-14s | %-12s | %-12s | %-12s |\n", "Extension", "Status", "Installed", "Available", "Recommended");
  printf("+%s+%s+%s+%s+%s+\n", "-"x22, "-"x16, "-"x14, "-"x14, "-"x14);
  my @list = ( $ext ) || sort(keys(%{$exts}));
  foreach my $name (@list) {
    printf("| %20s | %14s | %12s | %12s | %12s |\n", $name, $exts->{$name}->{status}, $exts->{$name}->{version} || "none", $exts->{$name}->{available}, "No");
  }
  printf("+%s+%s+%s+%s+%s+\n", "-"x22, "-"x16, "-"x14, "-"x14, "-"x14);
}

if ($ARGV[0] eq "-s" || $ARGV[0] eq "--status" ) {
  print_status($ARGV[1]);
} elsif ($ARGV[0] eq "-u" || $ARGV[0] eq "--update" ) {
  update();
} elsif ($ARGV[0] eq "-a" || $ARGV[0] eq "--auto" ) {
  recommended();
} elsif ($ARGV[0] eq "-i" || $ARGV[0] eq "--install" ) {
  download_latest($ARGV[1]);
  $exts = get_status();
  if ($exts->{$ARGV[1]}->{status} ne "inactive") {
    confess("Extension not found after download");
  }
} elsif ($ARGV[0] eq "-r" || $ARGV[0] eq "--remove" ) {
  if ($exts->{$ARGV[1]}->{status} eq "active") {
    `systemd-sysext unmerge`;
    unlink("$EXT_DIR/$ARGV[1].raw");
    unlink("$EXT_DIR/$ARGV[1].manifest");
    `systemd-sysext refresh`;
    `systemd-sysext merge`;
  } elsif (-e "$EXT_DIR/$ARGV[1].raw") {
    unlink("$EXT_DIR/$ARGV[1].raw");
    unlink("$EXT_DIR/$ARGV[1].manifest");
  } else {
    confess("$ARGV[1] is not installed");
  }
  $exts = get_status();
  print_status($ARGV[1]);
} else {
  usage()
}

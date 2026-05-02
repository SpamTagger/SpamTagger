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

use TOML qw( from_toml to_toml );
use JSON::XS qw( decode_json );
use LWP::UserAgent;
use File::Path qw( mkpath );
use Config;

our $ua = LWP::UserAgent->new();
our $cache = "/tmp/sysext-cache.toml";
our $exts;
our @installed;
our @active;
our $pci_ids;

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
  print("usage: $0 [-s|status|-i|install|-r|remove|-u|update|-a|auto] <package>

-s status       List supported extensions, installed status and versions. Package name option to
                list only details for that extension.
-i install      Fetch and merge the named system extension. Requires package name argument.
-r remove       Fetch and merge the named system extension. Requires package name argument.
-u update       Check for newer versions of already installed extensions and update them.
-a auto         Automatically install all recommened and requested extensions. This includes any
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
  $ext = "sysext-$ext" unless ($ext =~ m/^sysext-/);
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

sub download_latest($name) {
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

sub load_manifest() {
  my $manifest = "/usr/spamtagger/etc/sysext.toml";
  my ($FH, $toml);
  print "Checking upstream versions...\n";
  confess "Missing Extensions manifest $manifest\n" unless (-e $manifest);
  confess "Failed to open manifest $manifest\n" unless (open($FH, '<', $manifest));
  $toml .= $_ while (<$FH>);
  close($FH);
  confess "Failed to parse TOML from $manifest\n" unless ($exts = from_toml($toml));
  foreach my $ext (keys(%{$exts})) {
    print "Checking $ext...\n";
    $exts->{$ext}->{recommended} = 1 if defined($exts->{$ext}->{pci_id}) && check_pci_ids(@{$exts->{$ext}->{pci_id}});
    $exts->{$ext}->{recommended} = 1 if defined($exts->{$ext}->{dmi}) && check_dmi(@{$exts->{$ext}->{dmi}});
    $exts->{$ext}->{recommended} = 1 if defined($exts->{$ext}->{device_tree}) && check_device_tree(@{$exts->{$ext}->{device_tree}});
    $exts->{$ext}->{recommended} = 1 if defined($exts->{$ext}->{virt_env}) && check_virt_env(@{$exts->{$ext}->{virt_env}});
    $exts->{$ext}->{recommended} = 1 if defined($exts->{$ext}->{if_file}) && -e $exts->{$ext}->{if_file};
  }
  return $exts;
}

sub check_pci_ids(@ids) {
  unless (scalar(keys(%{$pci_ids}))) {
    my $lspci = `lspci -nn`;
    foreach my $pci (split(/\n/, $lspci)) {
      my ($vendor, $product) = $pci =~ m/.*\[([0-9a-f]{4}):([0-9a-f]{4})\](?: \(rev \d+\))?.*/;
      if (defined($pci_ids->{$vendor})) {
        push(@{$pci_ids->{$vendor}}, $product);
      } else {
        $pci_ids->{$vendor} = [ $product ];
      }
    }
  }
  foreach (@ids) {
    my ($v, $p) = $_ =~ m/^([^:]+)(?::([^:]+))?$/;
    print "Looking for '$v':'$p'...";
    next unless (defined($pci_ids->{$v}));
    return 1 unless $p;
    return 1 if (grep(/^$p$/, @{$pci_ids->{$v}}));
  }
}

sub check_dmi(@ids) {
  my ($vendor, $product, $id, $FH) = ("/sys/class/dmi/id/sys_vendor", "/sys/class/dmi/id/product_name");
  return 0 unless (-e $vendor);
  if (open($FH, '<', $vendor)) {
    $id .= $_ while (<$FH>);
    close($FH);
    chomp($id);
  }
  my $prod = "";
  foreach (@ids) {
    my ($v, $p) = $_ =~ m/^([^:]+)(?::([^:]+))?$/;
    next unless ($v eq $id);
    return 1 unless ($p);
    next unless (-e $product);
    unless ($prod) {
      if (open($FH, '<', $product)) {
        $prod .= $_ while (<$FH>);
        close($FH);
        chomp($prod);
      }
    }
    return 1 if ($p eq $prod);
  }
}

sub check_device_tree(@ids) {
  my ($compatible, $id, $FH) = ("/proc/device-tree/compatible");
  return 0 unless (-e $compatible);
  if (open($FH, '<', $compatible)) {
    $id .= $_ while (<$FH>);
    close($FH);
    chomp($id);
  }
  foreach (@ids) {
    next if ($_ eq '');
    return 1 if ($id =~ m/^$_/);
  }
}

sub check_virt_env(@ids) {
  my $virt = `systemd-detect-virt`;
  chomp($virt);
  return 0 unless $virt; # Not virtualized;
  foreach (@ids) {
    return 1 if ($_ eq $virt);
  }
}

sub get_status($ext = undef) {
  my ($FH, $toml, $e);
  if (-e $cache) {
    if (open($FH, '<', $cache)) {
      $toml .= $_ while (<$FH>);
      close($FH);
      if ($toml) {
        confess "Failed to parse TOML from $cache\n" unless ($e = from_toml($toml));
      }
      if (defined($e->{timestamp}) && $e->{timestamp} > (time() - 86400)) {
        return $e;
      } else {
        print "Cache is out of date. ";
      }
    } else {
      print "Cannot read cache file $cache\n";
    }
  }
  $e = load_manifest();
  my $json = `systemd-sysext status --json=short`;
  chomp($json);
  my $ret = decode_json($json) || confess("Could not parse current systemd-sysext status: $json\n");
  foreach my $hierarchy (@{$ret}) {
    push(@active, @{$hierarchy->{extensions}}) unless ($hierarchy->{extensions} eq "none");
  }
  foreach my $ext (keys(%{$e})) {
    my $installed = is_installed($ext);
    if ($installed) {
      $e->{$ext}->{version} = get_installed_version($ext);
      if ($installed == 1) {
        $e->{$ext}->{status} = "active";
      } elsif ($installed == 2) {
        $e->{$ext}->{status} = "inactive";
      } elsif ($installed == 3) {
        $e->{$ext}->{status} = "corrupt";
      } else {
        $e->{$ext}->{status} = "unknown";
      }
    } else {
      $e->{$ext}->{status} = "not installed";
    }
    $e->{$ext}->{available} = get_available_version($e, $ext);
  }
  if (open($FH, '>', $cache)) {
    $e->{timestamp} = time();
    print $FH to_toml($e) || print STDERR "Failed to write to cache file $cache: $!\n";
    close($FH);
  } else {
    print STDERR "Cannot open cache file $cache for writing: $!\n";
  }
  return $e;
}

sub is_installed($ext) {
  unless (scalar(@installed)) {
    my $json = `systemd-sysext list --json=short`;
    chomp($json);
    my $ret = decode_json($json) || confess("Could not parse current systemd-sysext status: $json\n");
    @installed = map { $_->{name} } (@{$ret});
  }
  if (-e "/var/lib/extensions/${ext}.raw") {
    if (scalar(@active) == 0) {
      return 2 if (scalar(@installed) && scalar(grep(/^${ext}/, @installed)));
      return 3;
    } elsif (grep(/^${ext}$/, @active)) {
      return 1;
    } else {
      return 2 if (scalar(@installed) && scalar(grep(/^${ext}/, @installed)));
      return 3;
    }
  }
}

sub print_status($ext = undef) {
  printf("+%s+%s+%s+%s+%s+\n", "-"x22, "-"x16, "-"x20, "-"x20, "-"x14);
  printf("| %-20s | %-14s | %-18s | %-18s | %-12s |\n", "Extension", "Status", "Installed", "Available", "Recommended");
  printf("+%s+%s+%s+%s+%s+\n", "-"x22, "-"x16, "-"x20, "-"x20, "-"x14);
  my @list = ( $ext ) || sort(keys(%{$exts}));
  foreach my $name (@list) {
    next unless (ref($exts->{$name}));
    printf(
      "| %20s | %14s | %18s | %18s | %12s |\n",
      $name, $exts->{$name}->{status},
      $exts->{$name}->{version} || "none",
      $exts->{$name}->{available},
      defined($exts->{$name}->{recommended}) ? "Yes" : "No"
    );
  }
  printf("+%s+%s+%s+%s+%s+\n", "-"x22, "-"x16, "-"x20, "-"x20, "-"x14);
}

usage() if (!defined($ARGV[0]) || $ARGV[0] eq "-h" || $ARGV[0] eq "help" );
$exts = get_status();
if ($ARGV[0] eq "-s" || $ARGV[0] eq "status" ) {
  print_status($ARGV[1]);
} elsif ($ARGV[0] eq "-u" || $ARGV[0] eq "update" ) {
  update();
} elsif ($ARGV[0] eq "-a" || $ARGV[0] eq "auto" ) {
  recommended();
} elsif ($ARGV[0] eq "-i" || $ARGV[0] eq "install" ) {
  download_latest($ARGV[1]);
  $exts = get_status();
  if ($exts->{$ARGV[1]}->{status} ne "inactive") {
    confess("Extension not found after download");
  }
} elsif ($ARGV[0] eq "-r" || $ARGV[0] eq "remove" ) {
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

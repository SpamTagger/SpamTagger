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
#   This script will dump the exim configuration file from the configuration
#   setting found in the database.
#
#   Usage:
#           dump_greylistd_config.pl
#

use v5.40;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

use lib "/opt/spamtagger/lib";
use STUtils qw(open_as);
use File::Touch;
use File::Path qw(make_path);

require DB;

my $DEBUG = 0;

my %greylist_conf = get_greylist_config();
my $trusted_ips = get_trusted_ips();

our $uid = getpwnam( 'greylist' );
our $gid = getgrnam( 'greylist' );
our $confdir = "/etc/greylistd";

foreach my $dir (
    "/var/spamtagger/spool/greylistd",
    "/var/spamtagger/run/greylistd"
) {
    make_path($dir, {'mode'=>0o755,'user'=>$uid,'group'=>$gid}) unless ( -d $dir );
}

if ( -e $confdir && !-l $confdir ) {
    unlink(glob($confdir."/*"));
    rmdir($confdir);
}

symlink("/opt/spamtagger/${confdir}", $confdir);

symlink('/opt/spamtagger/etc/apparmor', '/etc/apparmor.d/spamtagger') unless (-e '/etc/apparmor.d/spamtagger');

dump_greylistd_file(\%greylist_conf);

dump_domain_to_avoid($greylist_conf{'__AVOID_DOMAINS__'});

dump_trusted_ips($trusted_ips);

foreach my $dir (
    "/etc/greylistd",
    glob("/etc/greylistd/*"),
    "/var/spamtagger/spool/greylistd",
) {
    make_path($dir, {'mode'=>0o755,'user'=>$uid,'group'=>$gid}) unless ( -d $dir );
}

foreach my $file (
    glob("/var/spamtagger/spool/greylistd/*"),
    "/var/spamtagger/spool/tmp/spamtagger/domains_to_greylist.list",
    "/opt/spamtagger/${confdir}/config",
    "/opt/spamtagger/${confdir}/whitelist-hosts",
) {
    touch($file) unless(-f $file);
    chown($uid, $gid, $file);
}

sub get_greylist_config()
{
    my $replica_db = DB->db_connect('replica', 'st_config');

    my %configs = $replica_db->get_hash_row(
        "SELECT retry_min, retry_max, expire, avoid_domains FROM greylistd_config"
    );
    my %ret;

    $ret{'__RETRYMIN__'} = $configs{'retry_min'};
    $ret{'__RETRYMAX__'} = $configs{'retry_max'};
    $ret{'__EXPIRE__'} = $configs{'expire'};
    $ret{'__AVOID_DOMAINS__'} = $configs{'avoid_domains'};

    return %ret;
}

sub get_trusted_ips()
{
    my $replica_db = DB->db_connect('replica', 'st_config');

    my %configs = $replica_db->get_hash_row(
        "SELECT trusted_ips FROM antispam;"
    );

    return $configs{'trusted_ips'};
}

sub dump_domain_to_avoid($domains)
{
    my @domains_to_avoid;
    if (! $domains eq "") {
        @domains_to_avoid = split /\s*[\,\:\;]\s*/, $domains;
    }

    my $dir = "/var/spamtagger/spool/tmp/spamtagger/";
    make_path($dir, {'mode'=>0o755,'user'=>$uid,'group'=>$gid}) unless ( -d $dir );
    my $file = "${dir}/domains_to_avoid_greylist.list";
    my $DOMAINTOAVOID;
    confess "Cannot open $file: $!" unless ($DOMAINTOAVOID = ${open_as($file)} );

    foreach my $adomain (@domains_to_avoid) {
        print $DOMAINTOAVOID $adomain."\n";
    }
    close $DOMAINTOAVOID;
    return;
}

sub dump_trusted_ips($ips)
{
    my $file = "/opt/spamtagger/${confdir}/whitelist-hosts";
    unlink($file) if (-e $file);
    return 0 unless (defined($ips));
    return 0 if ($ips =~ /^\s*$/);
    my $TRUSTED_IPS;
    confess "Cannot open $file: $!" unless ($TRUSTED_IPS = ${open_as($file)} );
    print $TRUSTED_IPS $ips;
    close $TRUSTED_IPS;
    return;
}

sub dump_greylistd_file($greylistd_conf)
{
    my $template_file = "/opt/spamtagger/${confdir}/greylistd.conf_template";
    my $target_file = "/opt/spamtagger/${confdir}/config";

    my ($TEMPLATE, $TARGET);
    confess "Cannot open $template_file: $!\n" unless ($TEMPLATE = ${open_as($template_file, '<')} );
    confess "Cannot open $target_file: $!\n" unless ($TARGET = ${open_as($target_file)} );

    while(<$TEMPLATE>) {
        my $line = $_;

        foreach my $key (keys %{$greylistd_conf}) {
            $line =~ s/$key/$greylistd_conf->{$key}/g;
        }

        print $TARGET $line;
    }

    close $TEMPLATE;
    close $TARGET;
    return;
}

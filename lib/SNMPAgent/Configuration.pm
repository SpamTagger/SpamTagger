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

package SNMPAgent::Configuration;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

use lib "/usr/spamtagger/lib/";
use lib "/usr/rrdtools/lib/perl/";
use NetSNMP::agent();
use NetSNMP::OID (':all');
use NetSNMP::agent (':all');
use NetSNMP::ASN (':all');
use ReadConfig();

my $mib_root_position = 2;

my %mib_global = (1 => \&isMaster);
my %mib_status = ( 1 => \%mib_global);

my $conf;

sub init_agent {
  do_log('Agent Configuration initializing', 'status', 'debug');

  $conf = ReadConfig::get_instance();

  return $mib_root_position;
}


sub get_mib {
  return \%mib_status;
}

sub do_log ($message, $cat, $level) {
  SNMPAgent::do_log($message, $cat, $level);
  return;
}

##### Handlers
sub is_source {
  return (ASN_INTEGER, 1) if ($conf->get_option('ISSOURCE') eq 'Y');
  return (ASN_INTEGER, 0);
}

1;

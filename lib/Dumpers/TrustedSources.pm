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
#   This module will just read the configuration file

package Dumpers::TrustedSources;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

use lib '/usr/spamtagger/lib';
use DB();

sub get_specific_config {
  my $db = DB->db_connect('replica', 'st_config');

  my %config = ();
  my %row = $db->get_hash_row("SELECT use_alltrusted, use_authservers, useSPFOnLocal, useSPFOnGlobal, authservers, authstring, domainsToSPF, wantrbls FROM trustedSources");
  $config{'__USE_ALLTRUSTED__'} = $row{'use_alltrusted'};
  $config{'__USE_AUTHSERVERS__'} = $row{'use_authservers'};
  $config{'__USE_SPFONLOCAL__'} = $row{'useSPFOnLocal'};
  $config{'__USE_SPFONGLOBAL__'} = $row{'useSPFOnGlobal'};
  $config{'__AUTHSERVERS__'} = $row{'authservers'} || '';
  $config{'__AUTHSTRING__'} = $row{'authstring'} || '';
  $config{'__DOMAINSTOSPF__'} = $row{'domainsToSPF'} || '';
  $config{'__DOMAINSTOSPF__'} =~ s/\n//g;
  $config{'__DOMAINSTOSPF__'} =~ s/\s+/ /g;
  $config{'__WANTRBLS__'} = $row{'wantrbls'} || '';

  return %config;
}

1;

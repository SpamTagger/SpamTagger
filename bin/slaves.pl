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

use v5.40;
use warnings;
use utf8;

use lib '/usr/spamtagger/lib/';
use Term::ReadKey;
use DBI;
use ReadConfig;

our $config = ReadConfig::get_instance();

my $replica_dbh = DBI->connect(
  "DBI:mariadb:database=st_config;mariadb_socket=".$config->get_option('VARDIR')."/run/mariadb_replica/mariadbd.sock",
  "spamtagger", $config->get_option('MYSPAMTAGGERPWD'), {RaiseError => 0, PrintError => 0}
);

unless ($replica_dbh) {
  printf ("ERROR: no replica database found on this system.\n");
  exit 1;
}

sub view_replicas {
  my $sth =  $replica_dbh->prepare("SELECT id, hostname, port, ssh_pub_key  FROM replica") or die ("error in SELECT");
  $sth->execute() or die ("error in SELECT");
  my $el=$sth->rows;
  while (my $ref=$sth->fetchrow_hashref()) {
    printf $ref->{'hostname'}."\n";
  }
  $sth->finish();
  return;
}

view_replicas();

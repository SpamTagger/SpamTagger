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

package ElementMapper;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

use lib "/usr/spamtagger/lib/";
use SystemPref();

sub get_element_mapper ($what) {
  my $el;

  if ($what eq "domain") {
    require ElementMapper::DomainMapper;
    $el = ElementMapper::DomainMapper->new();
  }
  if ($what eq "email") {
    require ElementMapper::EmailMapper;
    $el = ElementMapper::EmailMapper->new();
  }

  $el->{db} = DB->db_connect('source', 'st_config', 0);
  if (! $el->{db}->ping()) {
    print "Cannot connect to configuration database";
    return;
  }

  return $el;
}

1;

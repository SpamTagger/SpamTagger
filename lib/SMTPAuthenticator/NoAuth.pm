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

package SMTPAuthenticator::NoAuth;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

sub new ($server, $port, $params = {}) {
  my $this = {
    error_text => "No authentication scheme available",
    error_code => -1,
  };

  bless $this, "SMTPAuthenticator::NoAuth";
  return $this;
}

sub authenticate ($this, $username, $password) {
  $this->{error_text} = "No authentication scheme available for user: $username";
  return 0;
}

1;

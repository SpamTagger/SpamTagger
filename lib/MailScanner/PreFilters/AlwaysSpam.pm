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

package MailScanner::AlwaysSpam;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

our $MODULE = 'AlwaysSpam';

sub initialise ($class = $MODULE) {
  MailScanner::Log::InfoLog("$class module initializing...");
  return bless {}, $class;
}

# TODO: Mixed case function name, hard-coded into MailScanner. Ignore in Perl::Critic
sub Checks ($this, $message) { ## no critic
  MailScanner::Log::InfoLog(blessed($this).' module checking... well guess what ? it\'s spam !');
  return 1;
}

sub dispose ($this) {
  MailScanner::Log::InfoLog(blessed($this).' module disposing...');
  return;
}

1;

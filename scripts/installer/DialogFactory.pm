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

package          DialogFactory;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

use lib "/usr/spamtagger/scripts/installer/";
use Model::InLine::SimpleDialog();
use Model::InLine::PasswordDialog();
use Model::InLine::ListDialog();
use Model::InLine::YesNoDialog();

sub new ($class, $model) {
  my $this = {
    model => $model
  };
  return bless $this, $class;
}

sub simple ($this) {
  if ($this->{model} eq 'InLine') {
    return Model::InLine::SimpleDialog->new();
  }
  return;
}

sub password ($this) {
  if ($this->{model} eq 'InLine') {
    return Model::InLine::PasswordDialog->new();
  }
  return;
}

sub list ($this) {
  if ($this->{model} eq 'InLine') {
    return Model::InLine::ListDialog->new();
  }
  return;
}

sub yes_no ($this) {
  if ($this->{model} eq 'InLine') {
    return Model::InLine::YesNoDialog->new();
  }
  return;
}

1;


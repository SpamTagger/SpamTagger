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

package Model::InLine::SimpleDialog ;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

use Term::ReadKey qw( ReadMode ReadKey );

sub new ($class) {

  my $this =  {
    text => '',
    default => ''
  };

  return bless $this, $class;
}

sub build($this, $text, $default='') {
  $this->{text} = $text;
  $this->{default} = $default;

  return $this;
}

sub display($this) {
  print $this->{text}.' '.(defined($this->{default}) ? "[".$this->{default}."]" : '[\'q\' to skip]').": ";
  ReadMode 'normal';
  my $result = <STDIN>;
  chomp $result;
  return 0 if ($result eq 'q');
  if ( $result eq "") {
    if (defined($this->{default})) {
      $result = $this->{default};
    } else {
      return $this->display();
    }
  }
  return $result;
}

sub clear($this) {
  system('clear');
  return;
}

1;

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

package Module::Keyboard;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

use lib "/usr/spamtagger/scripts/installer/";
use DialogFactory();

no strict 'refs';
require '/usr/share/console-setup/KeyboardNames.pl';

sub new($class) {
  return bless {}, $class;
}

sub run($this) {
  my $dfact = DialogFactory->new('InLine');
  my $dlg = $dfact->list();

  my $layouts = \%{"KeyboardNames::layouts"};
  my $variants = \%{"KeyboardNames::variants"};
  my $staged = {};
  foreach my $i (keys(%$layouts)) {
    next if ($layouts->{$i} eq 'custom');
    my ($lang, $country) = $i =~ m/(\w+)(?: \((.*)\))?/;
    if (defined($country)) {
      if (defined($staged->{$lang})) {
        $staged->{$lang}->{$country} = $layouts->{$i};
      } else {
        $staged->{$lang} = { $country => $layouts->{$i} };
      }
    } else {
      $staged->{$lang} = $layouts->{$i};
    }
  }
  my @langs = keys(%{$staged});
  $dlg->build('Select Language:', \@langs, 1, 0);
  my $res = $dlg->display();

  my $primary;
  if (ref($staged->{$res}) eq 'HASH') {
    my @regions = keys(%{$staged->{$res}});
    $dlg->build('Select Region:', \@regions, 1, 0);
    my $res2 = $dlg->display();
    $primary = $staged->{$res}->{$res2};
  } else {
    $primary = $staged->{$res}->[0];
  }

  my $variant = '';
  if (defined($variants->{$primary})) {
    my @vars = ( 'Standard', sort(keys(%{$variants->{$primary}})) );
    $dlg->build('Select Variant:', \@vars, 1, 1);
    my $res3 = $dlg->display();
    if ($res3 ne 'Standard') {
      $variant = $variants->{$primary}->{$res3};
    }
  }
  `sed -i 's/XKBLAYOUT=*/XKBLAYOUT="$primary"/' /etc/default/keyboard`;
  `sed -i 's/XKBVARIANT=*/XKBVARIANT="$variant"/' /etc/default/keyboard`;
  `setupcon --force`;
}

1;

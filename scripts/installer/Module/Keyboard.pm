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

require '/usr/share/console-setup/KeyboardNames.pl';

sub new($class) {
  return bless {}, $class;
}

sub run($this) {
  my $dfact = DialogFactory->new('InLine');
  my $dlg = $dfact->list();

  my %layouts = %KeyboardNames::layouts;
  my %variants = %KeyboardNames::variants;
  my $staged = {};
  foreach my $i (keys(%layouts)) {
    next if ($layouts{$i} eq 'custom');
    my ($lang, $country) = $i =~ m/(\w+)(?: \((.*)\))?/;
    if (defined($country)) {
      if (defined($staged->{$lang}) && $staged->{$lang} ne '') {
        $staged->{$lang}->{$country} = $layouts{$i};
      } else {
        $staged->{$lang} = { $country => $layouts{$i} };
      }
    } else {
      if (defined($staged->{$lang})) {
        $staged->{$lang}->{Standard} = $layouts{$i};
      } else {
        $staged->{$lang} = { 'Standard' => $layouts{$i} };
      }
    }
  }
  my @langs = keys(%{$staged});
  $dlg->build('Select Language:', \@langs, 1, 0);
  my $res = $dlg->display();

  my $primary;
  if (scalar(keys(%{$staged->{$res}})) > 1) {
    my @regions;
    if (defined($staged->{$res}->{Standard})) {
      push(@regions, 'Standard');
      foreach (sort(keys(%{$staged->{$res}})) ) {
        push(@regions, $_) unless ($_ eq 'Standard');
      }
    } else {
      @regions = sort(keys(%{$staged->{$res}}));
    }
    $dlg->build('Select Keyboard Region:', \@regions, 1, 1);
    my $res2 = $dlg->display();
    $primary = $staged->{$res}->{$res2};
  } else {
    $primary = $staged->{$res}->{Standard};
  }

  my $variant = '';
  if (defined($variants{$primary})) {
    my @vars = ( 'Standard', sort(keys(%{$variants{$primary}})) );
    $dlg->build('Select Variant:', \@vars, 1, 1);
    my $res3 = $dlg->display();
    if ($res3 ne 'Standard') {
      $variant = $variants{$primary}->{$res3};
    }
  }
  write_keyboard_file($primary, $variant);
  `setupcon --force 2>/dev/null`;
  return 1;
}

sub write_keyboard_file ($primary, $variant) {
  my ($output, $FILE) = ('');
  unless (open($FILE, '<', '/etc/default/keyboard')) {
    die "Failed to open '/etc/default/keyboard' for reading\n";
  }
  while (my $line = <$FILE>) {
    if ($line =~ m/XKBLAYOUT/) {
      $line =~ s/XKBLAYOUT=.*/XKBLAYOUT="$primary"/;
    } elsif ($line =~ m/XKBVARIANT/) {
      $line =~ s/XKBVARIANT=.*/XKBVARIANT="$variant"/;
    }
    $output .= $line;
  }
  close($FILE);
  unless (open($FILE, '>', '/etc/default/keyboard')) {
    die "Failed to open '/etc/default/keyboard' for writing\n";
  }
  print $FILE $output;
  close($FILE);
  return 1;
}

      
1;

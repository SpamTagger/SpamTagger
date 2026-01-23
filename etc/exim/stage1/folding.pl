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

# TODO: this has been significantly refactored and needs testing

my $headers = 1;
while (<>) {
  if ($headers && $_ =~ m/^$/) {
    print "X-SpamTagger-folding: Some lines in message modified for exceeding maximum line length\n";
    $headers = 0;
  }
  # Fold if length exceeds 998 characters (1000 with <CR><LF>)
  if (length($_) >= 998) {
    # Collect words as possible break points
    my @words = split(/(\s)/, $_);
    my @lines = ( '' );
    my $indent;
    while (scalar(@words)) {
      my $word = shift(@words);

      # Account for left padding if already on folded line.
      $indent = 1 if (scalar(@lines) > 1);

      # Calculate remaining available characters
      my $span = 998 - length(($indent ? ' ' : '').$lines[-1]);

      # Append words until available space is exceeded
      if (length($word) + 1 <= $span) {
        $lines[-1] .= ($lines[-1] eq '' ? '' : ' ').$word;
        next;
      }

      # If current word does not fit on this line, but it does fit entirely on next, put it there
      if (length($word) < 997) {
        push(@lines, $word);
        next;
      }

      # Break at commas, if possible
      my ($before, $after) = $word =~ m/^([^,]*),(.*)/;
      if (length($before)+1 < $span) {
        $lines[-1] .= " $before,";
        unshift(@words, $after);
        next;
      }

      # If it cannot fit entirely on a new line, and can't be broken, put as possible on this line
      my ($fits, $excess) =~ m/^(.{$span})(.*)/;
      $lines[-1] .= $fits;
      # Load the excess back into the word list for the next iteration
      unshift(@words, $excess);
      # Start a new line (which we know will have content)
      push(@lines, '');
    }

    print join("\n ", @lines)."\n";
  } else {
    print "$_";
  }
}

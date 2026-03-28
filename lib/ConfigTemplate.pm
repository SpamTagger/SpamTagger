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
#   This module will dump a configuration file based on template

package ConfigTemplate;

use v5.40;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = ();
our $VERSION   = 1.0;

use lib "/usr/spamtagger/lib";
use STUtils qw( open_as );
use Carp qw( confess );

###
# create the dumper
# @param  $infile        string  file path
#   Accepts most valid input paths or output paths:
#   * /etc/spamtagger/* - user defined configuration template
#   * /usr/spamtagger/* - system configuration template
#   * /usr/spamtagger/* - legacy system template
#   * /var/spamtagger/tmp/* - configuration output directory
#   * [^/]* - (relative path) will search for matching file in /(etc|opt)/spamtagger
#   Will also accomodate for `_template` if provided or not. Will only use the file with this
#   suffix present, but you can provide the argument with or without.
# @param  $targetfile  string  target config file
# @return              this
###
sub new ($class, $infile, $chown='spamtagger:spamtagger') {
  # Add `_template` suffix if missing
  $infile = "${infile}_template" unless ($infile =~ m/_template$/);
  my $outfile;
  # If a relative path is provided, search for a valid template file.
  if ($infile =~ m/^[^\/]/) {
    # Outfile with always be relative to `/var/spamtagger/tmp/`
    $outfile = "/var/spamtagger/tmp/${infile}";
    # Prefer user-defined template, if it exists
    if (-e "/etc/spamtagger/${infile}") {
      $infile = "/etc/spamtagger/${infile}";
      print("Using user-defined config template $infile\n");
    # Use system file if it does not
    } elsif (-e "/usr/spamtagger/${infile}") {
      $infile = "/usr/spamtagger/${infile}";
      print("Using default system template $infile\n");
    # Otherwise die if not found in either location
    } elsif ($infile =~ m/\.\./) {
      confess "Upward path traversal prohibited for $infile\n";
    } else {
      confess "No files found matching relative path $infile\n";
    }
  # If path is absolute, remove approved prefixes and provide required output prefix
  } else {
    confess "Unsupported input file: $infile" unless ($infile =~ m#^/(?:var/spamtagger(?:/tmp)?|(?:etc|opt|usr)/spamtagger)#);
    ($outfile) = $infile =~ m#^/(?:var/spamtagger(?:/tmp)?|(?:etc|opt|usr)/spamtagger)(.*)$#;
    $outfile = "/var/spamtagger/tmp/${outfile}";
  }
  confess "Template file $infile does not exist\n" unless (-e $infile);

  # Remove `_template` suffix from output
  $outfile =~ s/_template$//;

  my $this = {
    templatefile => $infile,
    targetfile => $outfile,
    replacements => {},
    subtemplates => {},
    conditions => {},
    chown => $chown
  };

  my ($overrides) = $infile =~ m#^/(?:var/spamtagger(?:/tmp)?|(?:etc|opt|usr)/spamtagger)(.*)_template$#;
  if (-e "/etc/spamtagger/${overrides}.toml") {
    $this->parse_overrides("/etc/spamtagger/${overrides}.toml");
  }

  bless $this, $class;

  $this->pre_parse_template();
  return $this;
}

###
# preparse template and variables
# @return        boolean   true on success, false on failure
###
sub pre_parse_template ($this) {

  my $in_template = "";
  my $FILE;
  return 0 unless (open($FILE, '<', $this->{templatefile}));
  while (<$FILE>) {
    my $line = $_;

    if ($line =~ /\_\_TMPL\_([A-Z0-9]+)\_START\_\_/) {
      $in_template = $1;
      $this->{subtemplates}{$in_template} = "";
      next;
    }
    if ($line =~ /\_\_TMPL\_([A-Z0-9]+)\_STOP\_\_/) {
      $in_template = "";
      next;
    }
    if ($in_template !~ /^$/) {
      $this->{subtemplates}{$in_template} .= $line;
      next;
    }
  }
  close $FILE;
  return 1;
}

###
# preparse overrides
#
# Optional user-defined file can be defined at `<template_file>.toml`. Options in the `variables`
# block with override the default `replacements` variables. Options in the `features` block will
# enable/disable conditional blocks.
#
# @param  $file  string  override file path
# @return        boolean   true on success, false on failure
###
sub parse_overrides ($this, $file) {
  my ($FH, $toml, $overrides);
  confess "Override file $file doesn't exist\n" unless (-e $file);
  confess "Failed to open $file override file\n" unless (open($FH, '<', $file));
  while (<$FH>) {
    $toml .= $_;
  }
  close($FH);
  confess "Failed to parse TOML from $file\n" unless ($overrides = from_toml($toml));
  $this->{override_vars} = $overrides->{variables};
  $this->{override_feat} = $overrides->{features};
}
  
sub get_sub_template ($this, $tmplname) {
  if (defined($this->{subtemplates}{$tmplname})) {
    return $this->{subtemplates}{$tmplname};
  }
  return "";
}

###
# set the tag replacement values
# @param  replace   array_h  handle of array of rplacements with tag as keys
# @return           boolean  true on success, false on failure
###
sub set_replacements ($this, $replace) {
  foreach my $tag (keys %{$replace}) {
    $this->{replacements}->{$tag} = $replace->{$tag};
  }
  foreach my $tag (keys %{$this->{override_vars}}) {
    $this->{replacements}->{$tag} = $this->{override_vars}->{$tag};
  }
  # Must load all override features again in case any exist but were not triggered by set_condition
  foreach my $tag (keys %{$this->{override_feat}}) {
    $this->{conditions}->{$tag} = $this->{override_feat}->{$tag};
  }
  return 1;
}

###
# dump to destination file
###
sub dump_file ($this) {
  my ($FILE, $TARGET);
  return 0 unless (open($FILE, '<', $this->{templatefile}));
  return 0 unless ($TARGET = ${open_as($this->{targetfile}, '>', 0o664, $this->{chown})});

  my $ret;
  my $in_hidden = 0;
  my $ev_hidden = 0;
  my @if_hist = ();
  my $if_hidden = 0;
  my $lc = 0;
  while (<$FILE>) {
    my $line = $_;
    $lc++;

    if ($line =~ /__IF__\s+(\S+)/) {
      if ($this->get_condition($1)) {
        push @if_hist, $1;
      } else {
        push @if_hist, "!".$1;
        $if_hidden++;
      }
      next;
    }

    if ($line =~ /__ELSE__\s+(\S+)/) {
      unless (scalar(@if_hist)) {
        die "__ELSE__ $1 without preceeding __IF__ (".$this->{templatefile}.":$lc)\n";
      }
      if ($if_hist[scalar(@if_hist)-1] eq $1) {
        $if_hist[scalar(@if_hist)-1] = '!' . $if_hist[scalar(@if_hist)-1];
        $if_hidden++;
      } elsif ($if_hist[scalar(@if_hist)-1] eq "!".$1) {
        $if_hist[scalar(@if_hist)-1] =~ s/^!//;
        $if_hidden--;
      } else {
        die "__ELSE__ tag $1 without preceeding __IF__ (".$this->{templatefile}.":$lc)\n";
      }
      next;
    }

    if ($line =~/__FI__/) {
      unless (scalar(@if_hist)) {
        die "__FI__ without preceeding __IF__ (".$this->{templatefile}.":$lc)\n";
      }
      if ($if_hist[scalar(@if_hist)-1] =~ /^!/) {
        $if_hidden--;
      }
      pop @if_hist;
      next;
    }

    if ($line =~  /__EVAL__\s+(.*)$/) {
      if (eval { "$1" }) {
        $ev_hidden = 1;
      } else {
        $ev_hidden = 0;
      }
      next;
    }
    if ($line =~/__LAVE__/) {
      $ev_hidden = 0;
      next;
    }
    # Includes a file in the exim configuration
    # First looks for a equivalent customised file
    if ($line =~/__INCLUDE__ *(.*)/) {
      next if ($if_hidden );
      my $inc_file = $1;
      my $path_file;
      $inc_file =~ s/_template$//;
      # .include_if_exists
      # Prefer user-defined file if it exists
      if ( -f "/etc/spamtagger/etc/exim/$inc_file" ) {
        $path_file = "/etc/spamtagger/etc/exim/$inc_file";
      # Fallback to system config
      } elsif ( -f "/usr/spamtagger/etc/exim/$inc_file" ) {
        $path_file = "/usr/spamtagger/etc/exim/$inc_file";
      } else {
        next;
      }

      my $PATHFILE;
      my @contains;
      if (open($PATHFILE, '<', $path_file)) {
        push(@contains,$_) while(<$PATHFILE>);
      }
      close($PATHFILE);
      $ret .= "$_\n" foreach (@contains);
      next;
    }
    if ($line =~  /\_\_TMPL\_([A-Z0-9]+)\_START\_\_/) {
      $in_hidden = 1;
      next;
    }
    if ($line =~ /\_\_TMPL\_([A-Z0-9]+)\_STOP\_\_/) {
      $in_hidden = 0;
      next;
    }

    if (!$in_hidden && !$if_hidden && !$ev_hidden) {
      $ret .= $line;
    }
  }
  close $FILE;
  ## do the replacements

  ## replace well known tags
  my %wellknown = (
  );

  ## replace given tags
  foreach my $tag (keys %{$this->{replacements}}) {
    if (!defined($this->{replacements}->{$tag})) {
      $this->{replacements}->{$tag} = "";
    }
    if ( defined ($ret) ) {
      $ret =~ s/$tag/$this->{replacements}->{$tag}/g;
    }
  }

  foreach my $tag ( keys %wellknown ) {
    if ( defined ($ret) ) {
      $ret =~ s/$tag/$wellknown{$tag}/g;
    }
  }

  if ( defined ($ret) ) {
    print $TARGET $ret;
  }
  close $TARGET;
  return 1;
}

sub set_condition ($this, $condition, $value) {
  # Must immediately set override value so that it is readable by get_condition
  if (defined($this->{override_feat}->{$condition})) {
    print "$condition overridden by TOML feature\n";
    $this->{conditions}->{$condition} = $this->{override_feat}->{$condition};
  } else {
    $this->{conditions}->{$condition} = $value;
  }
  return 1;
}

sub get_condition ($this, $condition) {
  if (defined($this->{conditions}->{$condition})) {
    return $this->{conditions}->{$condition};
  }
  return 0;
}

1;

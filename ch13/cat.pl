#!/usr/bin/perl
# file: cat.pl
# Figure 13.1: Reading from STDIN with IO::Getline

use strict;
use IO::Getline;
use IO::Select;

my $s     = IO::Select->new(\*STDIN);
my $stdin = IO::Getline->new(\*STDIN);
my $data;

while ($s->can_read) {
  my $rc = $stdin->getline($data) or last;
  print $data if $rc > 0;
}

die "Read error: ",$stdin->error if $stdin->error;

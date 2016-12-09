#!/usr/bin/perl
# file: read_three.pl
# Figure 2.4: Read three lines of text from standard input

use strict;
for (1..3) {
  last unless defined (my $line = <>);
  warn "Read_three got: $line";
}


#!/usr/bin/perl
# file: write_ten.pl
# Figure 2.3: Write ten lines of text to a pipe

use strict;
open (PIPE,"| read_three.pl") or die "Can't open pipe: $!";
select PIPE; $|=1; select STDOUT;

my $count = 0;
for (1..10) {
  warn "Writing line $_\n";
  print PIPE "This is line number $_\n" and $count++;
  sleep 1;
}
close PIPE or die "Can't close pipe: $!";

print "Wrote $count lines of text\n";

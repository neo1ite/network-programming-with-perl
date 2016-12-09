#!/usr/bin/perl
# file: write_ten_i.pl
# Figure 2.6: Ignoring PIPE exceptions.

use strict;

$SIG{PIPE} = 'IGNORE';

open (PIPE,"| read_three.pl") or die "Can't open pipe: $!";
select PIPE; $|=1; select STDOUT;

my $count=0;
for (1..10) {
  warn "Writing line $_\n";
  if (print PIPE "This is line number $_\n") {
    $count++;
  } else {
    warn "An error occurred during writing: $!\n";
    last;
  }
  sleep 1;
}
close PIPE or die "Can't close pipe: $!";

print "Wrote $count lines of text\n";

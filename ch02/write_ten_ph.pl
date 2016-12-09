#!/usr/bin/perl
# file: write_ten_ph.pl
# Figure 2.5: Intercepting the PIPE signal.

use strict;

my $ok = 1;
$SIG{PIPE} = sub { undef $ok };

open (PIPE,"| read_three.pl") or die "Can't open pipe: $!";
select PIPE; $|=1; select STDOUT;

my $count = 0;
for ($_=1; $ok && $_ <= 10; $_++) {
  warn "Writing line $_\n";
  print PIPE "This is line number $_\n" and $count++;
  sleep 1;
}
close PIPE or die "Can't close pipe: $!";

print "Wrote $count lines of text\n";

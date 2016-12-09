#!/usr/bin/perl
# file: interrupt.pl
# Figure 2.4: Catching the sigINT signal

use strict;
my $interruptions = 0;
$SIG{INT} = \&handle_interruptions;

while ($interruptions < 3) {
  print "I'm sleeping.\n";
  sleep(5);
}

sub handle_interruptions {
  $interruptions++;
  warn "Don't interrupt me!  You've already interrupted me ${interruptions}x.\n";
}


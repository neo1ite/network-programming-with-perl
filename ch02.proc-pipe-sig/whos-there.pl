#!/usr/bin/perl
# file: whos-there.pl

use strict;
my %who; # accumulate logins

open WHOFH, "who |" or die "Can't open who: $!";

while (<WHOFH>) {
    next unless /^(\S+)/;
    $who{$1}++;
}

foreach (sort { $who{$b} <=> $who{$a} } keys %who) {
    printf "%10s %d\n", $_, $who{$_};
}

close WHOFH or die "Close error: $!";

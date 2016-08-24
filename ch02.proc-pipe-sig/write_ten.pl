#!/usr/bin/perl
use strict;
use IO::Handle;

open( my $pipe, "| perl read_three.pl") or die "can't open pipe: $!";
$pipe->autoflush(1);

my $count = 0;
for (1..10) {
    warn "writing line $_\n";
    print {$pipe} "this is line number $_\n" and $count++;
    sleep 1;
}
close $pipe or die "Can't close pipe: $!";
print "wrote $count lines of text\n";

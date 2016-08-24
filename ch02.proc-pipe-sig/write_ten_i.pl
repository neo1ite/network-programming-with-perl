#!/usr/bin/perl
use strict;
use IO::Handle;

$SIG{PIPE} = 'IGNORE';

open( my $pipe, "| perl read_three.pl") or die "can't open pipe: $!";
$pipe->autoflush(1);

my $count = 0;
for (1..10) {
    warn "Writing line $_\n";
    if ($pipe->print("This is line number $_\n")) {
        $count++;
    } else {
        warn "An error occurred during writing: $!\n";
        last;
    }
    sleep 1;
}
close $pipe or die "Can't close pipe: $!";

print "Wrote $count lines of text\n";

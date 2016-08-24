#!/usr/bin/perl
use strict;
use IO::Handle;
use Errno ':POSIX';

$SIG{PIPE} = 'IGNORE';

open( my $pipe, "| perl read_three.pl") or die "can't open pipe: $!";
$pipe->autoflush(1);

my $count = 0;
for (1..10) {
    warn "Writing line $_\n";
    unless ($pipe->print("This is line number $_\n")) {
        last if $! == EPIPE; # on PIPE, just terminate the loop
        die "I/O error: $!"; # otherwise just die with an error message
    }
    ++$count;
    sleep 1;
}
close $pipe or die "Can't close pipe: $!";

print "Wrote $count lines of text\n";

#!/usr/bin/perl
use strict;
use IO::Handle;

my $ok = 1;
$SIG{PIPE} = sub { undef $ok };
open( my $pipe, "| perl read_three.pl") or die "can't open pipe: $!";
$pipe->autoflush(1);

my $count = 0;
for ($_=1; $ok && $_ <= 10; $_++) {
    warn "writing line $_\n";
    $pipe->print( "this is line number $_\n" ) and $count++;
    sleep 1;
}
close $pipe or die "Can't close pipe: $!";

print "wrote $count lines of text\n";

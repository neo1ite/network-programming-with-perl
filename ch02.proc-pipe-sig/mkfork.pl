#!/usr/bin/env perl
use v5.22;

my @children;

for my $i (1 .. 10) {
    my $pid = fork;
    if ($pid) {
        # say "just kicked off child process $pid";
        push @children, $pid;
    } else {
        say "this is fork #$i ($$)";
        exit;
    }
}

join $_ for @children;

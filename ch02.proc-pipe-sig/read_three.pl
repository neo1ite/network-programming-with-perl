#!/usr/bin/perl
use strict;
for (1..3) {
    last unless defined (my $line = <>);
    warn "read_three got: $line";
}

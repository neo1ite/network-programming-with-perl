#!/usr/bin/perl

use strict;
my $arg = shift || 10;

pipe(READER, WRITER) or die "Can't open pipe' $!\n";

if (fork == 0) { # first child writes to WRITER
    close READER;
    select WRITER; $| = 1;
    factorial($arg);
    exit 0;
}

if (fork == 0) { # second child writes to WRITER
    close READER;
    select WRITER; $| = 1;
    my $result = fibonacci($arg);
    exit 0;
}

# parent process closes WRITER and reads from READER
close WRITER;
print while <READER>;

sub factorial {
    my $target = shift;
    for (my($result,$i) = (1,1); $i <= $target; ++$i) {
        print "factorial($i) => ", $result *= $i, "\n";
    }
}

sub fibonacci {
    my $target = shift;
    my @fibs = (1,1);
    for (0 .. 9) {
        $fibs[$_] = $fibs[-1] + $fibs[-2] unless exists $fibs[$_];
        print "fibonacci(",$_+1,") => $fibs[$_]\n";
    }
}

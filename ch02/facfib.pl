#!/usr/bin/perl
# file: facfib.pl
# Figure 2.2: Using pipe() to create linked filehandles

use strict;
my $arg = shift || 10;

pipe(READER,WRITER) or die "Can't open pipe: $!\n";

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
  for (my $result = 1,my $i = 1; $i <= $target; $i++) {
    print "factorial($i) => ",$result *= $i,"\n";
  }
}

sub fibonacci {
  my $target = shift;
  for (my $result = 1,my $i = 1; $i <= $target; $i++) {
    print "fibonacci($i) => ",$result += $i,"\n";
  }
}

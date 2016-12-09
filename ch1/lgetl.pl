#!/usr/bin/perl
# file: lgetl.pl
# Figure 1.1: Read the first line of a local file

use IO::File;

my $file = shift;
my $fh   = IO::File->new($file);
my $line = <$fh>;
print $line;

#!/usr/bin/perl
# file: lgetr.pl
# Figure 1.2: Read the first line from a remote server

use IO::Socket;

my $server = shift;
my $fh     = IO::Socket::INET->new($server);
my $line   = <$fh>;
print $line;

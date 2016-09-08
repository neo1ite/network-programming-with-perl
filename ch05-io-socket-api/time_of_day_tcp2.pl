#!/usr/bin/perl

use strict;
use IO::Socket qw(:DEFAULT :crlf);

my $host = shift // 'localhost';
$/ = CRLF;

my $socket = IO::Socket::INET->new("$host:daytime")
    or die "Can't connect to daytime service at $host: $!\n";

chomp(my $time = $socket->getline);
print "$time\n";

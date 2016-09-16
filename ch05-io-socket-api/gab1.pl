#!/usr/bin/perl
use strict;
use feature 'say';

use IO::Socket qw(:DEFAULT :crlf);

my $host = shift or die "Usage: gab1.pl host [port]\n";
my $port = shift || 'echo';

my $socket = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port)
    or die "Can't connect: $!";

my ($from_server,$from_user);
LOOP:
while (1) {
    {
        local $/ = CRLF;
        last LOOP unless $from_server = <$socket>;
        chomp $from_server;
    }
    print $from_server, "\n";

    last unless $from_user = <>;
    chomp($from_user);
    print $socket $from_user,CRLF;
}

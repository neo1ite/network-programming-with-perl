#!/usr/bin/perl
# file: gab1.pl
# Figure 5.6: An incorrect implementation of a gab client

# warning: this doesn't really work

use strict;
use IO::Socket qw(:DEFAULT :crlf);

my $host = shift or die "Usage: gab1.pl host [port]\n";
my $port = shift || 'echo';

my $socket = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port)
  or die "Can't connect: $!";

my ($from_server,$from_user);

LOOP:
while (1) {
  {  # localize change to $/
    local $/ = CRLF;
    last LOOP unless $from_server = <$socket>;
    chomp $from_server;
  }
  print $from_server,"\n";

  last unless $from_user = <>;
  chomp($from_user);
  print $socket $from_user,CRLF;
}

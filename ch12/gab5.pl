#!/usr/bin/perl
# file: gab5.pl
# Figure 12.1: Interactive TCP client using multiplexing

# usage: gab5.pl [host] [port]

use strict;
use IO::Socket;
use IO::Select;
use constant BUFSIZE => 1024;

my $host = shift or die "Usage: gab5.pl host [port]\n";
my $port = shift || 'echo';

my $socket  = IO::Socket::INET->new("$host:$port") or die $@;
my $readers = IO::Select->new() or die "Can't create IO::Select read object";
$readers->add(\*STDIN);
$readers->add($socket);

my $buffer;

while (1) {

  my @ready = $readers->can_read;

  for my $handle (@ready) {

    if ($handle eq \*STDIN) {
      if (sysread(STDIN,$buffer,BUFSIZE) > 0) {
        syswrite($socket,$buffer);
      } else {
        $socket->shutdown(1);
      }
    }

    if ($handle eq $socket) {
      if (sysread($socket,$buffer,BUFSIZE) > 0) {
        syswrite(STDOUT,$buffer);
      } else {
        warn "Connection closed by foreign host.\n";
        exit 0;
      }
    }

  }
}


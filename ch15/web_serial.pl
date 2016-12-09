#!/usr/bin/perl -w
# file: web_serial.pl
# Figure 14.2: The baseline server handles requests serially

use strict;
use IO::Socket;
use Web;

my $port = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
				    Listen    => SOMAXCONN,
				    Reuse     => 1 ) or die "Can't create listen socket: $!";
while (my $c = $socket->accept) {
  handle_connection($c);
  close $c;
}
close $socket;


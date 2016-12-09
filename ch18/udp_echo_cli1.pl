#!/usr/bin/perl
# file: udp_echo_cli1.pl
# Figure 18.5: Echo client

# usage: udp_echo_cli1.pl [host] [port]

use strict;
use IO::Socket;
use constant MAX_MSG_LEN  => 5000;
my $msg_in;

my $host = shift || 'localhost';
my $port = shift || 'echo(7)';

my $sock = IO::Socket::INET->new(Proto=>'udp',PeerAddr=>"$host:$port")
  or die $@;

while (<>) {
  chomp;
  $sock->send($_)                  or die "send() failed: $!";
  $sock->recv($msg_in,MAX_MSG_LEN) or die "recv() failed: $!";

  print "$msg_in\n";
}

$sock->close;

__END__

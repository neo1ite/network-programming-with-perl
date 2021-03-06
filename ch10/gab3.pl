#!/usr/bin/perl
# file: gab3.pl
# Figure 10.4: A bytestream-oriented gab client

# usage: gab3.pl [host] [port]

use strict;
use IO::Socket;

use constant BUFSIZE => 1024;

my $host = shift or die "Usage: gab3.pl host [port]\n";
my $port = shift || 'echo';
my $data;

my $socket = IO::Socket::INET->new("$host:$port") or die $@;

my $child = fork();
die "Can't fork: $!" unless  defined $child;

if ($child) {
  $SIG{CHLD} = sub { exit 0 };
  user_to_host($socket);
  $socket->shutdown(1);
  sleep;

} else {
  host_to_user($socket);
  warn "Connection closed by foreign host.\n";

}

sub user_to_host {
  my $s = shift;
  syswrite($s,$data) while sysread(STDIN,$data,BUFSIZE);
}

sub host_to_user {
  my $s = shift;
  syswrite(STDOUT,$data) while sysread($s,$data,BUFSIZE);
}

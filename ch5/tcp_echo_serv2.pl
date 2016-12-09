#!/usr/bin/perl
# file: tcp_echo_serv2.pl
# Figure 5.4: The reverse echo server, using IO::Socket

# usage: tcp_echo_serv2.pl [port]

use strict;
use IO::Socket qw(:DEFAULT :crlf);
use constant MY_ECHO_PORT => 2007;
$/ = CRLF;
my ($bytes_out,$bytes_in) = (0,0);

my $quit = 0;
$SIG{INT} = sub { $quit++ }; 

my $port     = shift || MY_ECHO_PORT;

my $sock = IO::Socket::INET->new( Listen    => 20, 
                                  LocalPort => $port,
                                  Timeout   => 60*60,
                                  Reuse     => 1) 
  or die "Can't create listening socket: $!\n";

warn "waiting for incoming connections on port $port...\n";
while (!$quit) {
  next unless my $session = $sock->accept;

  my $peer = gethostbyaddr($session->peeraddr,AF_INET) || $session->peerhost;
  my $port = $session->peerport;
  warn "Connection from [$peer,$port]\n";

  while (<$session>) {
    $bytes_in  += length($_);       
    chomp;
    my $msg_out = (scalar reverse $_) . CRLF;
    print $session $msg_out;
    $bytes_out += length($msg_out);
  }
  warn "Connection from [$peer,$port] finished\n";
  close $session;
}

print STDERR "bytes_sent = $bytes_out, bytes_received = $bytes_in\n";
close $sock;

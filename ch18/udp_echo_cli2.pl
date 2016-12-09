#!/usr/bin/perl
# file: udp_echo_cli2.pl
# Figure 18.6: udp_echo_cli2.pl implements a timeout on recv()

# usage: udp_echo_cli2.pl [host] [port]

use strict;
use IO::Socket;

use constant MAX_MSG_LEN  => 5000;
use constant TIMEOUT      => 2;
use constant MAX_RETRIES  => 5;
my $msg_in;

my $host = shift || 'localhost';
my $port = shift || 'echo';

my $sock = IO::Socket::INET->new(Proto=>'udp',PeerAddr=>"$host:$port")
  or die $@;

while (<>) {
  chomp;

  my $retries = 0;
  do {
    $sock->send($_)       or die "send() failed: $!";
    eval {
      local $SIG{ALRM} = sub { ++$retries and die "timeout\n" };
      alarm(TIMEOUT);
      $sock->recv($msg_in,MAX_MSG_LEN)     or die "receive() failed: $!";
      alarm(0);
    };
    warn "Retrying...$retries\n" if $retries;
  } while $@ eq "timeout\n" and $retries < MAX_RETRIES;

  die "timeout\n" if $retries >= MAX_RETRIES;

  print $msg_in,"\n";
}

$sock->close;

__END__


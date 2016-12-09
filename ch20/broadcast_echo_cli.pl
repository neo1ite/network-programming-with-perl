#!/usr/bin/perl
# file: broadcast_echo_cli.pl
# Figure 20.2: An echo client that sends to the broadcast address

use IO::Socket;
use IO::Select;

my $addr = shift || '143.48.31.255';
my $port = shift || getservbyname('echo','udp');

my $socket = IO::Socket::INET->new(Proto => 'udp') or die $@;
$socket->sockopt(SO_BROADCAST() => 1)              or die "sockopt: $!";
my $dest   = sockaddr_in($port,inet_aton($addr));

my $select = IO::Select->new($socket,\*STDIN);
while (1) {
  my @ready = $select->can_read;
  foreach (@ready) {
    do_stdin()  if $_ eq \*STDIN;
    do_socket() if $_ eq $socket;
  }
}

sub do_stdin {
  my $data;
  sysread(STDIN,$data,1024)   || exit 0;  # get out of here on EOF
  send($socket,$data,0,$dest) or die "send(): $!";
}

sub do_socket {
  my $data;
  my $addr = recv($socket,$data,1024,0) or die "recv(): $!";
  my ($port,$peer) = sockaddr_in($addr);
  my $host = inet_ntoa($peer);
  print "received ",length($data)," bytes from $host:$port\n";
}

__END__


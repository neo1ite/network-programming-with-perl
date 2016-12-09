#!/usr/bin/perl
# file: tcp_echo_cli1.pl
# Figure 4.1: A TCP Echo Client

# usage: tcp_echo_cli1.pl [host] [port]

use strict;
use Socket;
use IO::Handle;
my ($bytes_out,$bytes_in) = (0,0);

my $host = shift || 'localhost';
my $port = shift || getservbyname('echo','tcp');

my $protocol = getprotobyname('tcp');
$host = inet_aton($host) or die "$host: unknown host";

socket(SOCK, AF_INET, SOCK_STREAM, $protocol) or die "socket() failed: $!";
my $dest_addr = sockaddr_in($port,$host);
connect(SOCK,$dest_addr) or die "connect() failed: $!";

SOCK->autoflush(1);

while (my $msg_out = <>) {
    print SOCK $msg_out;
    my $msg_in = <SOCK>;
    print $msg_in;

    $bytes_out += length($msg_out);
    $bytes_in  += length($msg_in);
}

close SOCK;
print STDERR "bytes_sent = $bytes_out, bytes_received = $bytes_in\n";

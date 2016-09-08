#!/usr/bin/perl

use strict;
use IO::Socket;
my ($bytes_out,$bytes_in) = (0,0);

my $host = shift // 'localhost';
my $port = shift // 'echo';

my $socket = IO::Socket::INET->new("$host:$port") or die $@;

while (defined(my $msg_out = STDIN->getline)) {
    print $socket $msg_out;
    my $msg_in = <$socket>;
    print $msg_in;

    $bytes_out += length($msg_out);
    $bytes_in += length($msg_in);
}

$socket->close or warn $@;
print STDERR "bytes_sent = $bytes_out, bytes_received = $bytes_in\n";

#!/usr/bin/perl
use strict;
use Socket;

use constant {
    DEFAULT_ADDR => '127.0.0.1',
    PORT         => 13,
    IPPROTO_TCP  => 6
};

my $address = shift || DEFAULT_ADDR;
my $packed_addr = inet_aton($address);
my $destination = sockaddr_in(PORT, $packed_addr);

socket(SOCK, PF_INET, SOCK_STREAM, IPPROTO_TCP) or die "Cant' make socket $!";

connect(SOCK, $destination);

print <SOCK>;

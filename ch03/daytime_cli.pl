#!/usr/bin/perl
# file: daytime_cli.pl
# Figure 3.4: A Daytime Client

use strict;
use Socket;

use constant DEFAULT_ADDR => '127.0.0.1';
use constant PORT         => 13;
use constant IPPROTO_TCP  => 6;

my $address = shift || DEFAULT_ADDR;
my $packed_addr = inet_aton($address);
my $destination = sockaddr_in(PORT,$packed_addr);

socket(SOCK,PF_INET,SOCK_STREAM,IPPROTO_TCP) or die "Can't make socket: $!";
connect(SOCK,$destination)                   or die "Can't connect: $!";

print <SOCK>;

#!/usr/bin/perl
# file: udp_daytime_cli2.pl
# Figure 18.2: UDP daytime client using IO::Socket

use strict;
use IO::Socket qw(:DEFAULT :crlf);
use constant MAX_MSG_LEN => 100;
$/ = CRLF;
my $data;

my $host = shift || 'localhost';
my $port = shift || 'daytime';

my $sock = IO::Socket::INET->new(Proto    => 'udp',
                                 PeerHost => $host,
                                 PeerPort => $port) or die $@;

$sock->send('Yo!')              or die "send() failed: $!\n";
$sock->recv($data,MAX_MSG_LEN)  or die "recv() failed: $!\n";

chomp($data);
print $data,"\n";

__END__

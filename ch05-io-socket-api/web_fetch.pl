#!/usr/bin/perl

use strict;
use IO::Socket qw(:DEFAULT :crlf);
$/ = CRLF . CRLF;
my $data;

my $url = shift or die "Usage: web_fetch.pl <URL>\n";

my ($host,$path) = $url =~ m!http://([^/]+)(/[^\#]*)!
    or die "Invalid URL.\n";

my $socket = IO::Socket::INET->new(PeerAddr => $host,
                                   PeerPort => 'http(80)')
or die "Can't connect: $!";

print $socket "GET $path HTTP/1.0", CRLF,CRLF;

my $header = <$socket>;     # read the header
$header =~ s/$CRLF/\n/g;    # replace CRLF with logical newline
print $header;

print $data while read($socket, $data, 1024) > 0;

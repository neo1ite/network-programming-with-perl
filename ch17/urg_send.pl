#!/usr/bin/perl
# file: urg_send.pl
# Figure 17.2: Simple urgent data sender client

use strict;
use IO::Socket;

my $HOST = shift || 'localhost';
my $PORT = shift || 2007;

my $socket = IO::Socket::INET->new("$HOST:$PORT") or die "Can't connect: $!";

$SIG{INT}  = sub { print "sending 1 byte of OOB data!\n";
                   send($socket,"!",MSG_OOB);
                 };
$SIG{QUIT} = sub { exit 0 };

for ('aa'..'az') {
  print "sending ",length($_)," bytes of normal data: $_\n";
  syswrite $socket,$_;
  1 until sleep 1;
}

__END__


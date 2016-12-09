#!/usr/bin/perl -w
# file: web_thread1.pl
# Figure 14.9: Threaded web server

use strict;
use IO::Socket;
use IO::Select;
use Thread;
use Daemon;
use Web;

use constant PIDFILE => '/tmp/web_thread.pid';

my $DONE = 0;
$SIG{INT}  = $SIG{TERM} = sub { $DONE++ };

my $port = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
                                    Listen    => SOMAXCONN,
                                    Reuse     => 1 ) or die "Can't create listen socket: $!";
my $IN = IO::Select->new($socket);

# create PID file, initialize logging, and go into the background
init_server(PIDFILE);

warn "Listening for connections on port $port\n";

# accept loop
while (!$DONE) {
  next unless $IN->can_read;
  next unless my $c = $socket->accept;
  Thread->new(\&do_thread,$c);
}

warn "Normal termination\n";

sub do_thread {
  my $c = shift;
  Thread->self->detach;
  handle_connection($c);
  close $c;
}

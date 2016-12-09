#!/usr/bin/perl -w
# file: web_fork.pl
# Figure 14.3: A forking web server

use strict;
use IO::Socket;
use IO::File;
use IO::Select;
use Daemon;
use Web;

use constant PIDFILE => '/tmp/web_fork.pid';

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
  my $child = launch_child();
  unless ($child) {
    close $socket;
    handle_connection($c);
    exit 0;
  }
  close $c;
}

warn "Normal termination\n";

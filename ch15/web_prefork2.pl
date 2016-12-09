#!/usr/bin/perl -w
# web_prefork2.pl
# Figure 14.5: This preforking server serializes accept() and
#              relaunches new children to replace old ones

use strict;
use IO::Socket;
use IO::File;
use Fcntl ':flock';
use Daemon;
use Web;

use constant PREFORK_CHILDREN  => 5;
use constant MAX_REQUEST       => 30;
use constant PIDFILE           => "/tmp/prefork.pid";
use constant DEBUG             => 1;

my $CHILD_COUNT = 0;   # number of children
my $DONE        = 0;   # set flag to true when server done

$SIG{INT}  = $SIG{TERM} = sub { $DONE++ };

my $port = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
                                    Listen    => SOMAXCONN,
                                    Reuse     => 1 ) or die "Can't create listen socket: $!";

# create PID file, initialize logging, and go into background
init_server(PIDFILE);

while (!$DONE) {
  make_new_child() while $CHILD_COUNT < PREFORK_CHILDREN;
  sleep;         # wait for a signal
}

kill_children();
warn "normal termination\n" if DEBUG;
exit 0;

sub make_new_child {
  my $child = launch_child(\&cleanup_child);
  if ($child) {  # child > 0, so we're the parent
    warn "launching child $child\n" if DEBUG;
    $CHILD_COUNT++;
  } else {
    do_child($socket);      # child handles incoming connections
    exit 0;                 # child is done
  }
}

sub do_child {
  my $socket = shift;
  my $lock = IO::File->new(PIDFILE,O_RDONLY) or die "Can't open lock file: $!";
  my $cycles = MAX_REQUEST;
  while ($cycles--) {
    flock($lock,LOCK_EX);
    last unless my $c = $socket->accept;
    flock($lock,LOCK_UN);
    warn "Child $$ handling connection\n" if DEBUG;
    handle_connection($c);
    close $c;
  }
  close $socket;
  close $lock;
}

sub cleanup_child {
  my $child = shift;
  $CHILD_COUNT--;
}

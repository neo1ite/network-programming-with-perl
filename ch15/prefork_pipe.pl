#!/usr/bin/perl -w
# prefork_pipe.pl
# Figure 14.7 Preforking server using a pipe for interprocess communication

use strict;
use IO::Socket;
use IO::File;
use IO::Select;
use Fcntl ':flock';
use Daemon;
use Web;

use constant PREFORK_CHILDREN  => 3;
use constant MAX_REQUEST       => 30;
use constant PIDFILE           => "/tmp/prefork.pid";
use constant HI_WATER_MARK     => 5;
use constant LO_WATER_MARK     => 2;
use constant DEBUG             => 1;

my $DONE        = 0;   # set flag to true when server done
my %STATUS      = ();

$SIG{INT}  = $SIG{TERM} = sub { $DONE++ };

my $port = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
                                    Listen    => SOMAXCONN,
                                    Reuse     => 1 ) or die "Can't create listen socket: $!";

# create a pipe for IPC
pipe(CHILD_READ,CHILD_WRITE) or die "Can't make pipe!\n";
my $IN = IO::Select->new(\*CHILD_READ);

# create PID file, initialize logging, and go into background
init_server(PIDFILE);

# prefork some children
make_new_child() for (1..PREFORK_CHILDREN);  

while (!$DONE) {

  if ($IN->can_read) { # got a message from one of the children
    my $message;
    next unless sysread(CHILD_READ,$message,4096);
    my @messages = split "\n",$message;
    foreach (@messages) {
      next unless my ($pid,$status) = /^(\d+) (.+)$/;
      if ($status ne 'done') {
        $STATUS{$pid} = $status;
      } else {
        delete $STATUS{$pid};
      }
    }
  }

  # get the list of idle children
  warn join(' ', map {"$_=>$STATUS{$_}"} keys %STATUS),"\n" if DEBUG;
  my @idle = sort {$a <=> $b} grep {$STATUS{$_} eq 'idle'} keys %STATUS;

  if (@idle < LO_WATER_MARK) {
    make_new_child() for (0..LO_WATER_MARK-@idle-1);  # bring the number up
  } elsif (@idle > HI_WATER_MARK) {
    my @goners = @idle[0..@idle - HI_WATER_MARK() - 1];   # kill the oldest ones
    my $killed = kill HUP => @goners;
    warn "killed $killed children\n" if DEBUG;
  }

}

warn "Termination received, killing children\n" if DEBUG;
kill_children();
warn "Normal termination.\n";
exit 0;

sub make_new_child {
  my $child = launch_child(\&cleanup_child);
  if ($child) {  # child > 0, so we're the parent
    warn "launching child $child\n" if DEBUG;
  } else {
    close CHILD_READ;          # no need to read from pipe
    do_child($socket);      # child handles incoming connections
    exit 0;                 # child is done
  }
}

sub do_child {
  my $socket = shift;
  my $lock = IO::File->new(PIDFILE,O_RDONLY) or die "Can't open lock file: $!";
  my $cycles = MAX_REQUEST;
  my $done = 0;

  $SIG{HUP} = sub { $done++ };
  while ( !$done && $cycles-- ) {
    syswrite CHILD_WRITE,"$$ idle\n";
    my $c;
    next unless eval {
      local $SIG{HUP} = sub { $done++; die };
      flock($lock,LOCK_EX);
      warn "child $$: calling accept()\n" if DEBUG;
      $c = $socket->accept;
      flock($lock,LOCK_UN);
    };
    syswrite CHILD_WRITE,"$$ busy\n";
    handle_connection($c);
    close $c;
  }
  warn "child $$ done\n" if DEBUG;
  syswrite CHILD_WRITE,"$$ done\n";
  close $_ foreach ($socket,$lock,\*CHILD_WRITE);
}

sub cleanup_child {
  my $child = shift;
  delete $STATUS{$child};
}

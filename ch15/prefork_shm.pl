#!/usr/bin/perl -w
# prefork_shm.pl
# Figure 14.8: An adaptive preforking server using shared memory

use strict;
use IO::Socket;
use IO::File;
use Fcntl ':flock';
use IPC::Shareable;
use Daemon;
use Web;

use constant PREFORK_CHILDREN  => 3;
use constant MAX_REQUEST       => 30;
use constant PIDFILE           => "/tmp/prefork.pid";
use constant HI_WATER_MARK     => 5;
use constant LO_WATER_MARK     => 2;
use constant SHM_GLUE          => 'PREf';
use constant DEBUG             => 1;

my $DONE        = 0;   # set flag to true when server done
my %STATUS      = ();

$SIG{INT}  = $SIG{TERM} = sub { $DONE++ };
$SIG{ALRM} = sub {};   # receive alarm clock signals, but do nothing

my $port = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
                                    Listen    => SOMAXCONN,
                                    Reuse     => 1 ) or die "Can't create listen socket: $!";
# create PID file, initialize logging, and go into background
init_server(PIDFILE);

# create a shared memory segment for child status
tie(%STATUS,'IPC::Shareable',SHM_GLUE,{ create=>1,exclusive=>1,destroy=>1,mode => 0600})
  or die "Can't tie \%STATUS to shared memory: $!";

# prefork some children
make_new_child() for (1..PREFORK_CHILDREN);  # prefork children

while (!$DONE) {
  sleep;  # sleep until a signal arrives (alarm clock or CHLD)

  # get the list of idle children
  warn join(' ', map {"$_=>$STATUS{$_}"} keys %STATUS),"\n" if DEBUG;
  my @idle = sort {$a <=> $b} grep {$STATUS{$_} eq 'idle'} keys %STATUS;

  if (@idle < LO_WATER_MARK) {
    make_new_child() for (0..LO_WATER_MARK-@idle-1);  # bring the number up
  } elsif (@idle > HI_WATER_MARK) {
    my @goners = @idle[0..@idle - HI_WATER_MARK() - 1];   # kill the oldest ones
    my $killed = kill HUP => @goners;
    warn "killed $killed children" if DEBUG;
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
  } else { # in child
    do_child($socket);      # child handles incoming connections
    exit 0;                 # child is done
  }
}

sub do_child {
  my $socket = shift;
  my %status;
  my $lock = IO::File->new(PIDFILE,O_RDONLY) or die "Can't open lock file: $!";
  my $cycles = MAX_REQUEST;
  my $done = 0;

  tie(%status,'IPC::Shareable',SHM_GLUE)
    or die "Child $$: can't tie \%status to shared memory: $!";

  $SIG{HUP} = sub { $done++; };
  while (!$done && $cycles--) {
    $status{$$} = 'idle'; kill ALRM=>getppid();
    my $c;
    next unless eval {
      local $SIG{HUP} = sub { $done++; die};
      flock($lock,LOCK_EX);
      warn "child $$: calling accept()\n" if DEBUG;
      $c = $socket->accept;
      flock($lock,LOCK_UN);
    };

    $status{$$} = 'busy'; kill ALRM=>getppid();
    handle_connection($c);
    close $c;
  }
  $status{$$} = 'done'; kill ALRM=>getppid();
  warn "child $$ done\n" if DEBUG;
  close $_ foreach ($socket,$lock);
}

sub cleanup_child {
  my $child = shift;
  delete $STATUS{$child};
}

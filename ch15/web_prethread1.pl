#!/usr/bin/perl -w
# web_prethread1.pl
# Figure 14.10: Prethreaded Web Server

use strict;
use IO::Socket;
use IO::File;
use IO::Select;
use Daemon;
use Web;
use Thread qw(cond_wait cond_broadcast);

use constant PIDFILE           => '/tmp/web_prethread.pid';
use constant PRETHREAD         => 5;
use constant MAX_REQUEST       => 30;
use constant HI_WATER_MARK     => 5;
use constant LO_WATER_MARK     => 2;
use constant DEBUG             => 1;

my $STATUS       = '';
my $ACCEPT_LOCK  = '';
my %STATUS       = ();
my $DONE         = 0;

$SIG{INT} = $SIG{TERM} = sub { $DONE++ };

my $port   = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
                                    Listen    => 100,
                                    Reuse     => 1 ) or die "Can't create listen socket: $!";
my $IN = IO::Select->new($socket);

init_server(PIDFILE);

launch_thread($socket) for (1..PRETHREAD);  # launch threads
while (!$DONE) {
  lock $STATUS;
  cond_wait $STATUS;

  warn join(' ', map {"$_=>$STATUS{$_}"} keys %STATUS),"\n" if DEBUG;

  my @idle = sort {$a <=> $b} grep {$STATUS{$_} eq 'idle'} keys %STATUS;

  if (@idle < LO_WATER_MARK) {
    launch_thread($socket) for (0..LO_WATER_MARK-@idle-1);     # bring the number up
  } 

  elsif (@idle > HI_WATER_MARK) {
    my @goners = @idle[0..@idle - HI_WATER_MARK - 1];   # kill the oldest ones
    status($_ => 'goner') foreach @goners;
    warn "decomissioning @goners\n" if DEBUG;
  }

}

warn "Server will terminate when last thread has finished...\n" if DEBUG;
status($_ => 'goner') foreach keys %STATUS;
exit 0;

sub launch_thread {
  my $socket = shift;
  my $thread = Thread->new(\&do_thread,$socket);
}

sub do_thread {
  my $socket = shift;
  my $cycles = MAX_REQUEST;
  my $tid = Thread->self->tid;
  my $c;
  warn "Thread $tid: starting\n" if DEBUG;
  Thread->self->detach;        # don't save thread status info
  status($tid => 'idle');

  while (status($tid) ne 'goner' && $cycles > 0) {
    next unless $IN->can_read(1);
    { 
      lock $ACCEPT_LOCK;
      next unless $c = $socket->accept;
    }
    $cycles--;
    status($tid => 'busy');
    warn "Thread $tid: handling connection\n" if DEBUG;
    handle_connection($c); close $c;
    status($tid => 'idle');
  }

  warn "Thread $tid done\n" if DEBUG;
  status($tid=>undef);
}

sub status {
  my $tid = shift;
  lock $STATUS;
  return $STATUS{$tid} unless @_;
  my $status = shift;
  if ($status) {
    $STATUS{$tid} = $status 
      unless defined $STATUS{$tid} and $STATUS{$tid} eq 'goner';
  } else {  
    delete $STATUS{$tid};
  }
  cond_broadcast $STATUS;
}

#!/usr/bin/perl -T
# file: eliza_hup.pl
# Figure 14.6:  Psychotherapist server that responds to HUP signal

use strict;
use lib '.';
use Chatbot::Eliza;
use IO::Socket;
use Daemon;

use constant PORT      => 1002;
use constant PIDFILE   => '/var/run/eliza_hup.pid';
use constant USER      => 'nobody';
use constant GROUP     => 'nogroup';
use constant ELIZA_HOME => '/home/ftp';

# signal handler for child die events
$SIG{TERM} = $SIG{INT} = \&do_term;
$SIG{HUP}  = \&do_hup;

my $port = $ARGV[0] || PORT;
my $listen_socket = IO::Socket::INET->new(LocalPort => $port,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die "Can't create a listening socket: $@" unless $listen_socket;
my $pid = init_server(PIDFILE,USER,GROUP,$port);

log_notice "Server accepting connections on port $port\n";

while (my $connection = $listen_socket->accept) {
  my $host = $connection->peerhost;
  my $child = launch_child(undef,ELIZA_HOME);
  if ($child == 0) {
    $listen_socket->close;
    log_notice("Accepting a connection from $host\n");
    interact($connection);
    log_notice("Connection from $host finished\n");
    exit 0;
  }
  $connection->close;
}

sub interact {
  my $sock = shift;
  STDIN->fdopen($sock,"r")  or die "Can't reopen STDIN: $!";
  STDOUT->fdopen($sock,"w") or die "Can't reopen STDOUT: $!";
  STDERR->fdopen($sock,"w") or die "Can't reopen STDERR: $!";
  $| = 1;
  my $bot = Chatbot::Eliza->new;
  $bot->command_interface;
}

sub do_term {
  log_notice("TERM signal received, terminating children...\n");
  kill_children();
  exit 0;
}

sub do_hup {
  log_notice("HUP signal received, reinitializing...\n");
  log_notice("Closing listen socket...\n");
  close $listen_socket;
  log_notice("Terminating children...\n");
  kill_children;
  log_notice("Trying to relaunch...\n");
  do_relaunch();
  log_die("Relaunch failed. Died");
}

sub Chatbot::Eliza::_testquit { 
  my ($self,$string) = @_; 
  return 1 unless defined $string;  # test for EOF 
  foreach (@{$self->{quit}}) { return 1 if $string =~ /\b$_\b/i };
} 

# prevents an annoying warning from Chatbot::Eliza module
sub Chatbot::Eliza::DESTROY { }

END { 
  log_notice("Server exiting normally\n") if $$ == $pid;
}

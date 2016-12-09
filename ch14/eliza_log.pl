#!/usr/bin/perl
# file: eliza_log.pl
# Figure 14.2: Psychotherapist daemon with logging

use strict;
use Chatbot::Eliza;
use IO::Socket;
use Daemon;

use constant PORT      => 12000;

# signal handler for child die events
$SIG{TERM} = $SIG{INT} = sub { exit 0; };

my $port = shift || PORT;
my $listen_socket = IO::Socket::INET->new(LocalPort => $port,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die "Can't create a listening socket: $@" unless $listen_socket;
my $pid = init_server();

log_notice "Server accepting connections on port $port\n";

while (my $connection = $listen_socket->accept) {
  log_die("Can't fork: $!") unless defined (my $child = fork());
  if ($child == 0) {
    $listen_socket->close;
    my $host = $connection->peerhost;
    log_notice("Accepting a connection from %s\n",$host);
    interact($connection);
    log_notice("Connection from %s finished\n",$host);
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

sub Chatbot::Eliza::_testquit { 
  my ($self,$string) = @_; 
  return 1 unless defined $string;  # test for EOF 
  foreach (@{$self->{quit}}) { return 1 if $string =~ /\b$_\b/i };
} 

END { 
  log_notice("Server exiting normally\n") if $$ == $pid;
}

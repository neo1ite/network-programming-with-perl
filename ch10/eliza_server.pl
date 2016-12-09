#!/usr/bin/perl
# file: eliza_server.pl
# Figure 10.3: Psychotherapist as a forking server

use strict;
use Chatbot::Eliza;
use IO::Socket;
use POSIX 'WNOHANG';

use constant PORT => 12000;

my $quit = 0;

# signal handler for child die events
$SIG{CHLD} = sub { while ( waitpid(-1,WNOHANG)>0 ) { } };

# signal handler for interrupt key and TERM signal
$SIG{INT} = sub { $quit++ };

my $listen_socket = IO::Socket::INET->new(LocalPort => PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1,
                                          Timeout   => 60*60,
                                         );
die "Can't create a listening socket: $@" unless $listen_socket;
warn "Server ready.  Waiting for connections...\n";   

while (!$quit) {

  next unless my $connection = $listen_socket->accept;

  defined (my $child = fork()) or die "Can't fork: $!";
  if ($child == 0) {
    $listen_socket->close;
    interact($connection);
    exit 0;
  }

  $connection->close;
}

sub interact {
  my $sock = shift;
  STDIN->fdopen($sock,"<")  or die "Can't reopen STDIN: $!";
  STDOUT->fdopen($sock,">") or die "Can't reopen STDOUT: $!";
  STDERR->fdopen($sock,">") or die "Can't reopen STDERR: $!";
  $|=1;
  my $bot = Chatbot::Eliza->new;
  $bot->command_interface();
}

#!/usr/bin/perl
# file: eliza_server_win32.pl
# Eliza server modified for win32 environments
# Requires the file Chatbot/Eliza/Server.pm

use strict;
use Chatbot::Eliza::Server;
use IO::Socket;

use constant PORT => 12000;

my $quit = 0;

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
  my $socket = shift;
  my $bot = Chatbot::Eliza::Server->new;
  $bot->command_interface($socket,$socket);
}

sub Chatbot::Eliza::_testquit { 
  my ($self,$string) = @_; 
  return 1 unless defined $string;  # test for EOF 
  foreach (@{$self->{quit}}) { return 1 if $string =~ /\b$_\b/i };
} 


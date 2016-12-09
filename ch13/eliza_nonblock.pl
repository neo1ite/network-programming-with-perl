#!/usr/bin/perl
# file: eliza_nonblock.pl
# Figure 13.4: A psychiatrist server using IO::LineBufferedSet

use strict;
use Chatbot::Eliza::Polite;
use IO::Socket;
use IO::LineBufferedSet;

my %SESSIONS;   # hash of Eliza objects, indexed by the socket

use constant PORT => 12000;

my $listen_socket = IO::Socket::INET->new(LocalPort => PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die "Can't create a listening socket: $@" unless $listen_socket;
my $session_set = IO::LineBufferedSet->new($listen_socket);

warn "Listening for connections...\n";

while (1) {

  my @ready = $session_set->wait;

  for my $session (@ready) {

    my $eliza;
    if ( !($eliza = $SESSIONS{$session}) ) { # new session
      $eliza = $SESSIONS{$session} = new Chatbot::Eliza::Polite;
      $session->write($eliza->welcome);
      next;
    } 

    # if we get here, it's an existing session
    my $user_input;
    my $bytes = $session->getline($user_input);
    if ($bytes > 0) {
      chomp($user_input);
      $session->write($eliza->one_line($user_input));
    }

    $session->close if !$bytes || $eliza->done;

  }  # end for my $handle (@ready)

}

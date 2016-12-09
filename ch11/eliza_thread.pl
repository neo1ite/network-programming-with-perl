#!/usr/bin/perl
# file: eliza_thread.pl
# Figure 11.1: Multithreaded psychiatrist server

use strict;
use IO::Socket;
use Thread;
use Chatbot::Eliza::Server;

use constant PORT => 12000;
my $listen_socket = IO::Socket::INET->new(LocalPort => PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die $@ unless $listen_socket;

warn "Listening for connections...\n";

while (my $connection = $listen_socket->accept) {
  Thread->new(\&interact,$connection);
}

sub interact {
  my $handle = shift;
  Thread->self->detach;
  Chatbot::Eliza::Server->new->command_interface($handle,$handle);
  $handle->close();
}

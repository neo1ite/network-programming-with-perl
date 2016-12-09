#!/usr/bin/perl
# file: echo.pl
# Figure 13.3: An echo server that uses IO::SessionSet

use strict;
use IO::SessionSet;

use constant PORT => 12000;

my $listen_socket = IO::Socket::INET->new(LocalPort => PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die "Can't create a listening socket: $@" unless $listen_socket;
my $session_set = IO::SessionSet->new($listen_socket);

warn "Listening for connections...\n";

while (1) {
  my @ready = $session_set->wait;

  for my $session (@ready) {
    my $data;
    if (my $rc = $session->read($data,4096)) {
      $session->write($data) if $rc > 0;
    } else {
      $session->close;
    }
  }

}

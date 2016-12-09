#!/usr/bin/perl
# file: eliza_select.pl
# Figure 12.2: Multiplexed psychiatrist server

use IO::Socket;
use IO::Select;
use Chatbot::Eliza::Polite;
use strict;

my %SESSIONS;   # hash of Eliza objects, indexed by the socket

use constant PORT => 12000;
my $listen_socket = IO::Socket::INET->new(LocalPort => PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die $@ unless $listen_socket;
my $readers = IO::Select->new() or die "Can't create IO::Select read object";
$readers->add($listen_socket);

warn "Listening for connections...\n";

while (1) {

  my @ready = $readers->can_read;

  for my $handle (@ready) {

    if ($handle eq $listen_socket) {  # do an accept
      my $connect = $listen_socket->accept();
      my $eliza = $SESSIONS{$connect} = new Chatbot::Eliza::Polite;
      syswrite($connect,$eliza->welcome);
      $readers->add($connect);
    }

    elsif (my $eliza = $SESSIONS{$handle}) {
      my $user_input;
      my $bytes = sysread($handle,$user_input,1024);

      if ($bytes > 0) {
        chomp($user_input);
        my $response = $eliza->one_line($user_input);
        syswrite($handle,$response);
      }

      if (!$bytes or $eliza->done) { # chatbot indicates session is done
        $readers->remove($handle);
        close $handle;
        delete $SESSIONS{$handle};
      }
    }

  }  # end for my $handle (@ready)

} # while can_read()

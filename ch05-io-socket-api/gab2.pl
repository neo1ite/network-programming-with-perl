#!/usr/bin/perl
use strict;
use feature 'say';
use IO::Socket qw(:DEFAULT :crlf);

my $host = shift or die "Usage: gab2.pl host [port]\n";
my $port = shift || "echo";

my $socket = IO::Socket::INET->new("$host:$port") or die $@;
my $child = fork;
die "Can't fork: $!" unless defined $child;

if ($child) {
    $SIG{CHILD} = sub { exit 0 };
    user_to_host($socket);
    $socket->shutdown(1);
    sleep;
} else {
    host_to_user($socket);
    warn "Connection closed by foreign host.\n";
}

sub user_to_host {
    my $s = shift;
    while (<>) {
        chomp;
        print $s $_,CRLF;
    }
}

sub host_to_user {
    my $s = shift;
    $/ = CRLF;
    while (<$s>) {
        chomp;
        say;
    }
}

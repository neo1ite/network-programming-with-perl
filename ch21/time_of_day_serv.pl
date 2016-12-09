#!/usr/bin/perl
# file: time_of_day_serv.pl
# Figure 21.4: Multicast time of day server

use IO::Socket;
use IO::Socket::Multicast;
use Sys::Hostname;

use constant PERIOD => 15;   # send multicast every 15 secs (roughly)

my $port = shift || 2070;
my $addr = shift || '224.225.226.227';
my $ttl  = shift || 31;    # keep within organization

# set up socket
my $sock = IO::Socket::Multicast->new() or die "Can't create socket: $!";

# set ttl
$sock->mcast_ttl($ttl) or die "Can't set ttl: $!";

# create address to transmit to
my $dest = sockaddr_in($port,inet_aton($addr));

# get hostname
my $hostname = hostname;

# main loop
while (1) {
  if (time % PERIOD == 0) { # even tick
    my $message = localtime() . '/' . $hostname;
    send ($sock,$message,0,$dest) || die "couldn't send: $!";
  }
  sleep 1;
}

__END__

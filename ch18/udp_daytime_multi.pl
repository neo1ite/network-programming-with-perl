#!/usr/bin/perl
# file: udp_daytime_multi.pl
# Figure 18.3: This time of day client contacts multiple hosts

# usage: udp_daytime_multi.pl host1 host2 host3...

use strict;
use IO::Socket qw(:DEFAULT :crlf);
use constant MAX_MSG_LEN  => 100;
use constant TIMEOUT      => 10;  # wait 10 seconds for all responses
$/ = CRLF;

$SIG{ALRM} = sub { die "timed out before receiving all responses\n" };

my $sock = IO::Socket::INET->new(Proto => 'udp') or die $@;
my $port = getservbyname('daytime','udp');

my $host_count = 0;
while (my $host = shift @ARGV) {

  my $dest = sockaddr_in($port,inet_aton($host));

  if ($sock->send('Yo!',0,$dest)) {
      warn "sent to $host...\n";
      $host_count++;
  } else {
      warn "$host: $!\n";
  }
}

warn "\nWaiting for responses...\n";

alarm(TIMEOUT);
while ($host_count-- > 0) {
  my $daytime;

  unless ($sock->recv($daytime,MAX_MSG_LEN)) {
    warn $!,"\n";
    next;
  }

  my $hostname = gethostbyaddr($sock->peeraddr,AF_INET) || $sock->peerhost;
  chomp($daytime);
  print "$hostname: $daytime\n";
}
alarm(0);

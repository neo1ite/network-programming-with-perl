#!/usr/bin/perl
# file: urg_recv2.pl
# Figure 17.3: A server that processes urgent data with SO_OOBINLINE modification

use strict;
use IO::Socket;
use Fcntl;

my $PORT = shift || 2007;
my ($sock,$data);

$SIG{URG} = sub {
  my $r = recv($sock,$data,100,MSG_OOB);
  print $r ? ("got ",length($data)," bytes of urgent data: $data\n")
           : ("recv() error: $!\n");
};

my $listen = IO::Socket::INET->new( Listen    => 15,
                                    LocalPort => $PORT,
                                    Reuse     => 1) or die "Can't listen: $!";
warn "Listening on port $PORT...\n";

$sock = $listen->accept;
$sock->sockopt(SO_OOBINLINE,1);  # enable inline urgent data

# set the owner for the socket so that we get sigURG
fcntl($sock,F_SETOWN,$$) or die "Can't set owner: $!";

# echo the data
while (sysread $sock,$data,1024) {
  print "got ",length($data)," bytes of normal data: $data\n";
}

__END__

#!/usr/bin/perl
# file: localtime_serv.pl
# Figure 22.3: localtime_serv.pl, Daytime server

use IO::Socket;

use constant SOCK_PATH     => '/tmp/localtime';

# get path
my $path = shift || SOCK_PATH;

# handle interrupt key and termination
$SIG{TERM} = $SIG{INT} = sub { exit 0 };

# set umask to be world writable
umask(0111);
my $sock = IO::Socket::UNIX->new( Local => $path,
                                  Type  => SOCK_DGRAM) or die "Socket: $!";
warn "listening on UNIX path $path...\n";

while (1) {
  my $data;
  my $peer = recv($sock,$data,128,0);
  if ($data =~ m!^[a-zA-Z0-9/_-]+$!) { # could be a timezone
    $ENV{TZ} = $data;
  } else {
    delete $ENV{TZ};
  }
  send($sock,scalar localtime,0,$peer) || warn "Couldn't send: $!";
}

END { unlink $path if $path } 

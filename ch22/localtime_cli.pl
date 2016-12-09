#!/usr/bin/perl
# file: localtime_cli.pl
# Figure 22.4: localtime_cli.pl, Daytime Client

use IO::Socket;
use POSIX 'tmpnam';
use Getopt::Long;

use constant SOCK_PATH     => '/tmp/localtime';
use constant TIMEOUT       => 1;

my $path;
GetOptions("path=s" => \$path);
$path ||= SOCK_PATH;
my $local = tmpnam();

$SIG{TERM} = $SIG{INT} = sub { exit 0 };

# set umask to be world writable
umask(0111);
my $sock = IO::Socket::UNIX->new( Type  => SOCK_DGRAM,
                                  Local => $local,
                                ) or die "Socket: $!";

my $timezone = shift || ' ';
my $peer     = sockaddr_un($path);

send($sock,$timezone,0,$peer) or die "Couldn't send(): $!";

my $data;
eval {
  local $SIG{ALRM} = sub { die "timeout\n" };
  alarm(TIMEOUT);
  recv($sock,$data,128,0)       or die "Couldn't recv(): $!";
  alarm(0);
} or die "Couldn't get response: $@";

print $data,"\n";

END { unlink $local if $local }

__END__

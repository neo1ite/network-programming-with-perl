#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl} -w
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
# file: time_of_day_cli.pl
# Figure 21.5: Time of Day Multicast Client

use IO::Socket;
use IO::Socket::Multicast;

my $port = shift || 2070;
my $addr = shift || '224.225.226.227';

# set up socket
my $sock = IO::Socket::Multicast->new(LocalPort=>$port)
  or die "Can't create socket: $!";

# add multicast address
$sock->mcast_add($addr) or die "mcast_add: $!";
while (1) {
  my ($message,$peer);
  die "recv error: $!" unless $peer = recv($sock,$message,1024,0);
  my ($port,$peeraddr) = sockaddr_in($peer);
  print inet_ntoa($peeraddr) . ": $message\n";
}

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

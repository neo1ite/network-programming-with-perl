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
# file: udp_echo_serv.pl
# Figure 18.4: A UDP reverse-echo server

# usage: udp_echo_serv.pl [port]

use strict;
use IO::Socket;
use constant MY_ECHO_PORT => 2007;
use constant MAX_MSG_LEN  => 5000;

my $port = shift || MY_ECHO_PORT;

$SIG{'INT'} = sub { exit 0 };

my $sock = IO::Socket::INET->new(Proto=>'udp',
                                 LocalPort=>$port) or die $@;

my ($msg_in,$msg_out);
warn "servicing incoming requests....\n";
while (1) {
  next unless $sock->recv($msg_in,MAX_MSG_LEN);
  my $peerhost = gethostbyaddr($sock->peeraddr,AF_INET) || $sock->peerhost;
  my $peerport = $sock->peerport;
  my $length   = length($msg_in);

  warn "Received $length bytes from [$peerhost,$peerport]\n";

  $msg_out = reverse $msg_in;
  $sock->send($msg_out) or die "send(): $!\n";
}

$sock->close;

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

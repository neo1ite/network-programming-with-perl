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
# file: udp_echo_cli1.pl
# Figure 18.5: Echo client

# usage: udp_echo_cli1.pl [host] [port]

use strict;
use IO::Socket;
use constant MAX_MSG_LEN  => 5000;
my $msg_in;

my $host = shift || 'localhost';
my $port = shift || 'echo(7)';

my $sock = IO::Socket::INET->new(Proto=>'udp',PeerAddr=>"$host:$port")
  or die $@;

while (<>) {
  chomp;
  $sock->send($_)                  or die "send() failed: $!";
  $sock->recv($msg_in,MAX_MSG_LEN) or die "recv() failed: $!";

  print "$msg_in\n";
}

$sock->close;

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

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
# file: udp_echo_cli2.pl
# Figure 18.6: udp_echo_cli2.pl implements a timeout on recv()

# usage: udp_echo_cli2.pl [host] [port]

use strict;
use IO::Socket;

use constant MAX_MSG_LEN  => 5000;
use constant TIMEOUT      => 2;
use constant MAX_RETRIES  => 5;
my $msg_in;

my $host = shift || 'localhost';
my $port = shift || 'echo';

my $sock = IO::Socket::INET->new(Proto=>'udp',PeerAddr=>"$host:$port")
  or die $@;

while (<>) {
  chomp;

  my $retries = 0;
  do {
    $sock->send($_)       or die "send() failed: $!";
    eval {
      local $SIG{ALRM} = sub { ++$retries and die "timeout\n" };
      alarm(TIMEOUT);
      $sock->recv($msg_in,MAX_MSG_LEN)     or die "receive() failed: $!";
      alarm(0);
    };
    warn "Retrying...$retries\n" if $retries;
  } while $@ eq "timeout\n" and $retries < MAX_RETRIES;

  die "timeout\n" if $retries >= MAX_RETRIES;

  print $msg_in,"\n";
}

$sock->close;

__END__

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

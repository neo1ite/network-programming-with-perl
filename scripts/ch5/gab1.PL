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
# file: gab1.pl
# Figure 5.6: An incorrect implementation of a gab client

# warning: this doesn't really work

use strict;
use IO::Socket qw(:DEFAULT :crlf);

my $host = shift or die "Usage: gab1.pl host [port]\n";
my $port = shift || 'echo';

my $socket = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port)
  or die "Can't connect: $!";

my ($from_server,$from_user);

LOOP:
while (1) {
  {  # localize change to $/
    local $/ = CRLF;
    last LOOP unless $from_server = <$socket>;
    chomp $from_server;
  }
  print $from_server,"\n";

  last unless $from_user = <>;
  chomp($from_user);
  print $socket $from_user,CRLF;
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

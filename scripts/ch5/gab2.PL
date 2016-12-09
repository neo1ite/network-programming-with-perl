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
# file: gab2.pl
# Figure 5.8: A working implementation of a gab client

# usage: gab2.pl [host] [port]
# Forking TCP network client

use strict;
use IO::Socket qw(:DEFAULT :crlf);

my $host = shift or die "Usage: gab2.pl host [port]\n";
my $port = shift || 'echo';

my $socket = IO::Socket::INET->new("$host:$port") or die $@;

my $child = fork();
die "Can't fork: $!" unless  defined $child;

if ($child) {
  $SIG{CHLD} = sub { exit 0 };
  user_to_host($socket);
  $socket->shutdown(1);
  sleep;

} else {
  host_to_user($socket);
  warn "Connection closed by foreign host.\n";
}

sub user_to_host {
  my $s = shift;
  while (<>) {
    chomp;
    print $s $_,CRLF;
  }
}

sub host_to_user {
  my $s = shift;
  $/ = CRLF;
  while (<$s>) {
    chomp;
    print $_,"\n";
  }
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

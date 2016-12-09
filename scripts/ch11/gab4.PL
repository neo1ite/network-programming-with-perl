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
# file: gab4.pl
# Figure 11.3: Threaded concurrent client

# usage: gab4.pl [host] [port]

use strict;
use IO::Socket;
use Thread;

use constant BUFSIZE => 1024;
$SIG{TERM} = sub { exit 0 };

my $host = shift or die "Usage: gab4.pl host [port]";
my $port = shift || 'echo';

my $socket = IO::Socket::INET->new("$host:$port") or die $@;

# thread reads from socket, writes to STDOUT
my $read_thread = Thread->new(\&host_to_user,$socket);

# main thread reads from STDIN, writes to socket
user_to_host($socket);
$socket->shutdown(1);

$read_thread->join;

sub user_to_host {
  my $s = shift;
  my $data;
  syswrite($s,$data) while sysread(STDIN,$data,BUFSIZE);  
}

sub host_to_user {
  my $s = shift;
  my $data;
  syswrite(STDOUT,$data) while sysread($s,$data,BUFSIZE);
  exit 0;
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

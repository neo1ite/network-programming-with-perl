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
# file: gab7.pl
# Figure 14.1: The gab7.pl script uses IO::Poll to multiplex input and output

# usage: gab7.pl [host] [port]

use strict;
use IO::Socket;
use IO::Poll 0.04 qw(POLLIN POLLOUT POLLERR POLLHUP);
use Errno qw(EWOULDBLOCK);
use constant MAXBUF => 8192;
$SIG{PIPE} = 'IGNORE';
my ($to_stdout,$to_socket,$stdin_done,$sock_done);

my $host = shift or die "Usage: pollnet.pl host [port]\n";
my $port = shift || 'echo';
my $socket  = IO::Socket::INET->new("$host:$port") or die $@;

my $poll = IO::Poll->new() or die "Can't create IO::Poll object";
$poll->mask(\*STDIN => POLLIN);
$poll->mask($socket => POLLIN);

$socket->blocking(0);  # turn off blocking on the socket
STDOUT->blocking(0);   # and on STDOUT

while ($poll->handles) {

  $poll->poll;

  #handle readers
  for my $handle ($poll->handles(POLLIN|POLLHUP|POLLERR)) {

    if ($handle eq \*STDIN) {
      $stdin_done++ unless sysread(STDIN,$to_socket,2048,length $to_socket);
    }

    elsif ($handle eq $socket) {
      $sock_done++ unless sysread($socket,$to_stdout,2048,length $to_stdout);
    }
  }

  # handle writers
  for my $handle ($poll->handles(POLLOUT|POLLERR)) {

    if ($handle eq \*STDOUT) {
      my $bytes = syswrite(STDOUT,$to_stdout);
      unless ($bytes) {
        next if $! == EWOULDBLOCK;
        die "write to stdout failed: $!";
      }
      substr($to_stdout,0,$bytes) = '';
    }

    elsif ($handle eq $socket) {
      my $bytes = syswrite($socket,$to_socket);
      unless ($bytes) {
        next if $! == EWOULDBLOCK;
        die "write to socket failed: $!";
      }
      substr($to_socket,0,$bytes) = '';
    }
  }

} continue {
  my ($outmask,$inmask,$sockmask) = (0,0,0);

  $outmask  = POLLOUT if     length $to_stdout > 0;

  $inmask   = POLLIN  unless length $to_socket >= MAXBUF 
                               or ($sock_done || $stdin_done);

  $sockmask  = POLLOUT unless length $to_socket == 0      or $sock_done;
  $sockmask |= POLLIN  unless length $to_stdout >= MAXBUF or $sock_done;

  $poll->mask(\*STDIN  => $inmask);
  $poll->mask(\*STDOUT => $outmask);
  $poll->mask($socket  => $sockmask);

  $socket->shutdown(1) if $stdin_done and !length($to_socket);
}

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

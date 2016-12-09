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
# file: eliza_inetd.pl
# Figure 10.8: Inetd psychotherapist in wait mode

use strict;
use Chatbot::Eliza;
use IO::Socket;
use POSIX 'WNOHANG';

use constant TIMEOUT => 1; # 1 minute
my $timeout  = shift || TIMEOUT;

# signal handler for child die events
$SIG{CHLD} = sub { while ( waitpid(-1,WNOHANG)>0 ) { } };

# retrieve socket from STDIN
die "STDIN is not a socket" unless -S STDIN;
my $listen_socket = IO::Socket->new_from_fd(\*STDIN,"+<")
  or die "Can't create socket: $!";

while (1) {

  my $connection = eval {
    local $SIG{ALRM} = sub { die "timeout" };
    alarm ($timeout * 60);
    return $listen_socket->accept;
  };
  alarm(0);
  exit 0 unless $connection;

  die "Can't fork: $!" unless defined (my $child = fork());
  if ($child == 0) {
    $listen_socket->close;
    interact($connection);
    exit 0;
  }
  $connection->close;
}

sub interact {
  my $sock = shift;
  STDIN->fdopen($sock,"<")  or die "Can't reopen STDIN: $!";
  STDOUT->fdopen($sock,">") or die "Can't reopen STDOUT: $!";
  STDERR->fdopen($sock,">") or die "Can't reopen STDERR: $!";
  STDOUT->autoflush(1);
  my $bot = Chatbot::Eliza->new;
  $bot->command_interface;
}

sub Chatbot::Eliza::_testquit { 
  my ($self,$string) = @_; 
  return 1 unless defined $string;  # test for EOF 
  foreach (@{$self->{quit}}) { return 1 if $string =~ /\b$_\b/i };
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

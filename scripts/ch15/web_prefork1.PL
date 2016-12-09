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
# web_prefork1.pl
# Figure 14.4: Preforking web server, version 1

use IO::Socket;
use IO::File;
use Daemon;
use Web;

use constant PIDFILE          => "/tmp/prefork.pid";
use constant PREFORK_CHILDREN  => 5;

my $port = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
                                    Listen    => 100,
                                    Reuse     => 1 ) or die "Can't create listen socket: $!";

# create PID file, initialize logging, and go into background
init_server(PIDFILE);

make_new_child() for (1..PREFORK_CHILDREN);
exit 0;

sub make_new_child {
  my $child = launch_child();
  return if $child;
  do_child($socket);      # child handles incoming connections
  exit 0;
}

sub do_child {
  my $socket = shift;
  while (1) {
    next unless my $c = $socket->accept;
    handle_connection($c);
    close $c;
  }
  close $socket;
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

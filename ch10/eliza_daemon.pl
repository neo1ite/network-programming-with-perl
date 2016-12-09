#!/usr/bin/perl
# file: eliza_daemon.pl
# Figure 10.6: The Eliza server (forking version) with daemon code

use strict;
use Chatbot::Eliza;
use IO::Socket;
use IO::File;
use POSIX qw(WNOHANG setsid);

use constant PORT      => 12000;
use constant PID_FILE  => '/var/tmp/eliza.pid';
my $quit = 0;

# signal handler for child die events
$SIG{CHLD} = sub { while ( waitpid(-1,WNOHANG)>0 ) { } };
$SIG{TERM} = $SIG{INT} = sub { $quit++ };

my $fh = open_pid_file(PID_FILE);
my $listen_socket = IO::Socket::INET->new(LocalPort => shift || PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1,
                                          Timeout   => 60*60,
                                         );
die "Can't create a listening socket: $@" unless $listen_socket;

warn "$0 starting...\n";
my $pid = become_daemon();
print $fh $pid;
close $fh;

while (!$quit) {

  next unless my $connection = $listen_socket->accept;

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
  $| = 1;
  my $bot = Chatbot::Eliza->new;
  $bot->command_interface;
}

sub become_daemon {
  die "Can't fork" unless defined (my $child = fork);
  exit 0 if $child;    # parent dies;
  setsid();     # become session leader
  open(STDIN, "</dev/null");
  open(STDOUT,">/dev/null");
  open(STDERR,">&STDOUT");
  chdir '/';           # change working directory
  umask(0);            # forget file mode creation mask
  $ENV{PATH} = '/bin:/sbin:/usr/bin:/usr/sbin';
  return $$;
}

sub open_pid_file {
  my $file = shift;
  if (-e $file) {  # oops.  pid file already exists
    my $fh = IO::File->new($file) || return;
    my $pid = <$fh>;
    die "Server already running with PID $pid" if kill 0 => $pid;
    warn "Removing PID file for defunct server process $pid.\n";
    die "Can't unlink PID file $file" unless -w $file && unlink $file;
  }
  return IO::File->new($file,O_WRONLY|O_CREAT|O_EXCL,0644)
    or die "Can't create $file: $!\n";
}

sub Chatbot::Eliza::_testquit { 
  my ($self,$string) = @_; 
  return 1 unless defined $string;  # test for EOF 
  foreach (@{$self->{quit}}) { return 1 if $string =~ /\b$_\b/i };
} 

END { unlink PID_FILE if $$ == $pid; }

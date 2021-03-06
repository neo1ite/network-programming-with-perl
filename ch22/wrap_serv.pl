#!/usr/bin/perl
# file: wrap_serv.pl
# Figure 22.1: wrap_serv.pl, the text formatting server

use IO::Socket;
use POSIX qw(:signal_h WNOHANG);
use Text::Wrap 'fill';

use constant SOCK_PATH     => '/tmp/wrapserv';
use constant COLUMNS       => 40;
use constant INITIAL_TAB   => "\n";
use constant SUBSEQUENT_TAB => "";

# get path
my $path = shift || SOCK_PATH;

# set up Text::Wrap
$Text::Wrap::columns = COLUMNS;

# reap children to avoid zombies
$SIG{CHLD} = sub { do {} while waitpid(-1,WNOHANG) > 0 };

# handle interrupt key and termination
$SIG{TERM} = $SIG{INT} = sub { unlink $path; exit 0 };

# set umask
umask(0111);

my $listen = IO::Socket::UNIX->new( Local => $path, 
                                    Listen => SOMAXCONN ) or die "Socket: $!";
warn "listening on UNIX path $path...\n";

while (1) {
  my $connected = $listen->accept();
  die "Can't fork!" unless defined (my $child = launch_child());
  if ($child) {
    close $connected;
  } else {
    close $listen;
    interact($connected);
    exit 0;
  }
}

sub launch_child {
  my $signals = POSIX::SigSet->new(SIGINT,SIGCHLD,SIGTERM,SIGHUP);
  sigprocmask(SIG_BLOCK,$signals);  # block inconvenient signals
  return unless defined (my $child = fork());
  unless ($child) {
    $SIG{$_} = 'DEFAULT' foreach qw(HUP INT TERM CHLD);
  }
  sigprocmask(SIG_UNBLOCK,$signals);  # unblock signals
  return $child;
}

sub interact {
  my $c = shift;
  chomp(my @lines = <$c>);
  print $c fill(INITIAL_TAB, SUBSEQUENT_TAB, @lines);
  close $c;
}

__END__


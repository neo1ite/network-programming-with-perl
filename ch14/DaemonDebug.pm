package DaemonDebug;

# file: DaemonDebug.pm
# Chapter 14/Appendix A: The DaemonDebug module exports the same functions as the Daemon
# module described in Chapter 14.  However, it remains in the foreground and
# leaves standard error open.  This makes it easier to debug server applications during
# development.

use strict;
use vars qw(@EXPORT @ISA @EXPORT_OK $VERSION);

use POSIX qw(:signal_h WNOHANG);
use Carp 'croak','cluck';
use File::Basename;
use IO::File;
require Exporter;

@EXPORT_OK = qw(init_server prepare_child kill_children 
                launch_child do_relaunch
                log_debug log_notice log_warn 
                log_die %CHILDREN);
@EXPORT = @EXPORT_OK;
@ISA = qw(Exporter);
$VERSION = '1.00';

use constant PIDPATH  => '/tmp';
use vars '%CHILDREN';
my ($pid,$pidfile,$saved_dir,$CWD);

sub init_server {
  $pidfile = shift;
  $pidfile ||= getpidfilename();
  my $fh = open_pid_file($pidfile);
  print $fh $$;
  close $fh;
  $SIG{CHLD} = \&reap_child;
  return $pid = $$;
}

sub launch_child {
  my $callback = shift;
  my $signals = POSIX::SigSet->new(SIGINT,SIGCHLD,SIGTERM,SIGHUP);
  sigprocmask(SIG_BLOCK,$signals);  # block inconvenient signals
  log_die("Can't fork: $!") unless defined (my $child = fork());
  if ($child) {
    $CHILDREN{$child} = $callback || 1;
  } else {
    $SIG{HUP} = $SIG{INT} = $SIG{CHLD} = $SIG{TERM} = 'DEFAULT';
  }
  sigprocmask(SIG_UNBLOCK,$signals);  # unblock signals
  return $child;
}

sub reap_child {
  while ( (my $child = waitpid(-1,WNOHANG)) > 0) {
    $CHILDREN{$child}->($child) if ref $CHILDREN{$child} eq 'CODE';
    delete $CHILDREN{$child};
  }
}

sub kill_children {
  kill TERM => $_ foreach keys %CHILDREN;
  # wait until all the children die
  sleep while %CHILDREN;
}

sub do_relaunch { }  # no-op

sub log_debug  { &warn }
sub log_notice { &warn }
sub log_warn   { &warn }
sub log_die { &die }

sub getpidfilename {
  my $basename = basename($0,'.pl');
  return PIDPATH . "/$basename.pid";
}

sub open_pid_file {
  my $file = shift;
  if (-e $file) {  # oops.  pid file already exists
    my $fh = IO::File->new($file) || return;
    my $pid = <$fh>;
    croak "Invalid PID file" unless $pid =~ /^(\d+)$/;
    croak "Server already running with PID $1" if kill 0 => $1;
    cluck "Removing PID file for defunct server process $pid.\n";
    croak"Can't unlink PID file $file" unless -w $file && unlink $file;
  }
  return IO::File->new($file,O_WRONLY|O_CREAT|O_EXCL,0644)
    || die "Can't create $file: $!\n";
}

END {  unlink $pidfile if $$ == $pid  }

1;
__END__

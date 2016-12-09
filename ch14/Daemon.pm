package Daemon;
# file Daemon.pm
# Figure 14.7:  Daemon.pm module with support for restarting the server

# NOTE: this is the full-featured version of the Daemon module from the end
# of chapter 14.  See Daemon1.pm for the simpler version.

use strict;
use vars qw(@EXPORT @ISA @EXPORT_OK $VERSION);

use POSIX qw(:signal_h setsid WNOHANG);
use Carp 'croak','cluck';
use Carp::Heavy;
use File::Basename;
use IO::File;
use Cwd;
use Sys::Syslog qw(:DEFAULT setlogsock);
require Exporter;

@EXPORT_OK = qw(init_server prepare_child kill_children 
                launch_child do_relaunch
                log_debug log_notice log_warn 
                log_die %CHILDREN);
@EXPORT = @EXPORT_OK;
@ISA = qw(Exporter);
$VERSION = '1.00';

use constant PIDPATH  => '/var/run';
use constant FACILITY => 'local0';
use vars qw(%CHILDREN);
my ($pid,$pidfile,$saved_dir,$CWD);

sub init_server {
  my ($user,$group);
  ($pidfile,$user,$group) = @_;
  $pidfile ||= getpidfilename();
  my $fh = open_pid_file($pidfile);
  become_daemon();
  print $fh $$;
  close $fh;
  init_log();
  change_privileges($user,$group) if defined $user && defined $group;
  return $pid = $$;
}

sub become_daemon {
  croak "Can't fork" unless defined (my $child = fork);
  exit 0 if $child;    # parent dies;
  POSIX::setsid();     # become session leader
  open(STDIN,"</dev/null");
  open(STDOUT,">/dev/null");
  open(STDERR,">&STDOUT");
  $CWD = getcwd;       # remember working directory
  chdir '/';           # change working directory
  umask(0);            # forget file mode creation mask
  $ENV{PATH} = '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin';
  delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
  $SIG{CHLD} = \&reap_child;
}

sub change_privileges {
  my ($user,$group) = @_;
  my $uid = getpwnam($user)  or die "Can't get uid for $user\n";
  my $gid = getgrnam($group) or die "Can't get gid for $group\n";
  $) = "$gid $gid";
  $( = $gid;
  $> = $uid;   # change the effective UID (but not the real UID)
}

sub launch_child {
  my $callback = shift;
  my $home     = shift;
  my $signals = POSIX::SigSet->new(SIGINT,SIGCHLD,SIGTERM,SIGHUP);
  sigprocmask(SIG_BLOCK,$signals);  # block inconvenient signals
  log_die("Can't fork: $!") unless defined (my $child = fork());
  if ($child) {
    $CHILDREN{$child} = $callback || 1;
  } else {
    $SIG{HUP} = $SIG{INT} = $SIG{CHLD} = $SIG{TERM} = 'DEFAULT';
    prepare_child($home);
  }
  sigprocmask(SIG_UNBLOCK,$signals);  # unblock signals
  return $child;
}

sub prepare_child {
  my $home = shift;
  if ($home) {
    local($>,$<) = ($<,$>);   # become root again (briefly)
    chdir  $home || croak "chdir(): $!";
    chroot $home || croak "chroot(): $!";
  }
  $< = $>;  # set real UID to effective UID
}

sub reap_child {
  while ( (my $child = waitpid(-1,WNOHANG)) > 0) {
    $CHILDREN{$child}->($child) if ref $CHILDREN{$child} eq 'CODE';
    delete $CHILDREN{$child};
  }
}

sub kill_children {
  kill TERM => keys %CHILDREN;
  # wait until all the children die
  sleep while %CHILDREN;
}

sub do_relaunch {
  $> = $<;  # regain privileges
  chdir $1 if $CWD =~ m!([./a-zA-z0-9_-]+)!;
  croak "bad program name" unless $0 =~ m!([./a-zA-z0-9_-]+)!;
  my $program = $1;
  my $port = $1 if $ARGV[0] =~ /(\d+)/;
  unlink $pidfile;
  exec 'perl','-T',$program,$port or croak "Couldn't exec: $!";
}

sub init_log {
  setlogsock('unix');
  my $basename = basename($0);
  openlog($basename,'pid',FACILITY);
  $SIG{__WARN__} = \&log_warn;
  $SIG{__DIE__}  = \&log_die;
}

sub log_debug  { syslog('debug',_msg(@_))  }
sub log_notice { syslog('notice',_msg(@_)) }
sub log_warn   { syslog('warning',_msg(@_))   }
sub log_die {
  syslog('crit',_msg(@_)) unless $^S;
  die @_;
}
sub _msg {
  my $msg = join('',@_) || "Something's wrong";
  my ($pack,$filename,$line) = caller(1);
  $msg .= " at $filename line $line\n" unless $msg =~ /\n$/;
  $msg;
}

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
    or die "Can't create $file: $!\n";
}

END { 
  $> = $<;  # regain privileges
  unlink $pidfile if defined $pid and $$ == $pid 
}

1;
__END__

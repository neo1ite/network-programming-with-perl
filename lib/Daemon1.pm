package Daemon1;
# file: Daemon1.pm
# Figure 14.1: A module for daemonizing servers

# NOTE: See Daemon.pm for the full-featured Daemon module of Figure 14.7

use strict;
use vars qw(@EXPORT @ISA @EXPORT_OK $VERSION);

use POSIX qw(setsid WNOHANG);
use Carp 'croak','cluck';
use File::Basename;
use IO::File;
use Sys::Syslog qw(:DEFAULT setlogsock);
require Exporter;

@EXPORT_OK = qw( init_server log_debug log_notice log_warn log_die);
@EXPORT = @EXPORT_OK;
@ISA = qw(Exporter);
$VERSION = '1.00';

use constant PIDPATH  => '/usr/tmp';
use constant FACILITY => 'local0';
my ($pid,$pidfile);

sub init_server {
  $pidfile = shift || getpidfilename();
  my $fh = open_pid_file($pidfile);
  become_daemon();
  print $fh $$;
  close $fh;
  init_log();
  return $pid = $$;
}

sub become_daemon {
  die "Can't fork" unless defined (my $child = fork);
  exit 0 if $child;             # parent dies;
  setsid();                     # become session leader
  open(STDIN, "</dev/null");
  open(STDOUT,">/dev/null");
  open(STDERR,">&STDOUT");
  chdir '/';                    # change working directory
  umask(0);                     # forget file mode creation mask
  $ENV{PATH} = '/bin:/sbin:/usr/bin:/usr/sbin';
  $SIG{CHLD} = \&reap_child;
  return $$;
}

sub init_log {
  setlogsock('unix');
  my $basename = basename($0);
  openlog($basename,'pid',FACILITY);
}

sub log_debug  { syslog('debug',_msg(@_))  }
sub log_notice { syslog('notice',_msg(@_)) }
sub log_warn   { syslog('warning',_msg(@_))   }
sub log_die {
  syslog('crit',_msg(@_));   
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
  if (-e $file) {               # oops.  pid file already exists
    my $fh = IO::File->new($file) || return;
    my $pid = <$fh>;
    croak "Server already running with PID $pid" if kill 0 => $pid;
    cluck "Removing PID file for defunct server process $pid.\n";
    croak"Can't unlink PID file $file" unless -w $file && unlink $file;
  }
  return IO::File->new($file,O_WRONLY|O_CREAT|O_EXCL,0644)
    or die "Can't create $file: $!\n";
}

sub reap_child {
  do { } while waitpid(-1,WNOHANG) > 0;
}

END { unlink $pidfile if defined $pid and $$ == $pid }

1;

package LogFile;
# file: LogFile.pm
# Figure 14.3: Logging to a File

use IO::File;
use Fcntl ':flock';
use Carp 'croak';

use strict;
use vars qw(@ISA @EXPORT);
require Exporter;
@ISA = 'Exporter';
@EXPORT = qw(DEBUG NOTICE WARNING CRITICAL 
             init_log set_priority
             log_debug log_notice log_warn log_die);

use constant DEBUG    => 0;
use constant NOTICE   => 1;
use constant WARNING  => 2;
use constant CRITICAL => 3;

my ($PRIORITY,$fh);  # globals

sub init_log {
  my $filename = shift;
  $fh       = IO::File->new($filename,O_WRONLY|O_APPEND|O_CREAT,0644) || return;
  $fh->autoflush(1);
  $PRIORITY = DEBUG;   # log all
  $SIG{__WARN__} = \&log_warn;
  $SIG{__DIE__}  = \&log_die;
  return 1;
}

sub log_priority {
  $PRIORITY = shift if @_;
  return $PRIORITY;
}

sub _msg {
  my $priority = shift;
  my $time = localtime;
  my $msg = join('',@_) || "Something's wrong";
  my ($pack,$filename,$line) = caller(1);
  $msg .= " at $filename line $line\n" unless $msg =~ /\n$/;
  return "$time [$priority] $msg";
}

sub _log {
  my $message = shift;
  flock($fh,LOCK_EX);
  print $fh $message;
  flock($fh,LOCK_UN);
}

sub log_debug  { 
  return unless DEBUG >= $PRIORITY;
  _log(_msg('debug',@_));
}
sub log_notice { 
  return unless NOTICE >= $PRIORITY;
  _log(_msg('notice',@_));
}
sub log_warn { 
  return unless WARNING >= $PRIORITY;
  _log(_msg('warning',@_));
}
sub log_die {
  return unless CRITICAL >= $PRIORITY;
  _log(_msg('critical',@_));
  die @_;
}

1;

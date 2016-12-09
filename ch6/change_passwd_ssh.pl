#!/usr/bin/perl
# Figure 6.6: Changing passwords over a Secure Shell connection
# file: change_passwd_ssh.pl

use strict;
use Net::Telnet;
use Getopt::Long;
use IO::Pty;
use POSIX 'setsid';

use constant PROMPT  => '/[%>] $/';
use constant DEBUG => 1;

use constant USAGEMSG => <<USAGE;
Usage: change_passwd.pl [options] machine1, machine2, ...
Options: 
        --user  <user>  Login name
        --old   <pass>  Current password
        --new   <pass>  New password
USAGE

my ($USER,$OLD,$NEW);
die USAGEMSG unless GetOptions('user=s'  => \$USER,
                               'old=s'   => \$OLD,
                               'new=s'   => \$NEW);
$USER ||= $ENV{LOGNAME};
$OLD  or die "provide current password with --old\n";
$NEW  or die "provide new password with --new\n";

change_passwd($_,$USER,$OLD,$NEW) foreach @ARGV;

sub change_passwd {
  my ($host,$user,$oldpass,$newpass) = @_;
  my $ssh = do_cmd('ssh',"-l$user",$host) 
    or die "couldn't launch ssh subprocess";

  my $shell = Net::Telnet->new(Fhopen => $ssh);
  $shell->binmode(1);
  $shell->input_log('passwd.log') if DEBUG;
  $shell->errmode('return');

  $shell->waitfor('/password: /');
  $shell->print($oldpass);
  $shell->waitfor(PROMPT) or return "host refused login: wrong password?\n";

  $shell->print('passwd');
  $shell->waitfor('/Old password:/') or return warn "$host: ",$shell->errmsg,"\n";

  $shell->print($oldpass);
  my($pre,$match) = $shell->waitfor(Match => '/Incorrect password/',
                                    Match => '/New password:/');
  $match =~ /New/ or return warn "$host: Incorrect password.\n";

  $shell->print($newpass);
  ($pre,$match) = $shell->waitfor(Match => '/Bad password/',
                                  Match => '/Re-enter new password:/');
  $match =~ /Re-enter/ or return warn "$host: New password rejected.\n";

  $shell->print($newpass);
  $shell->waitfor('/Password changed\./')
    or return warn "$host: ",$shell->errmsg,"\n";

  print "Password changed for $user on $host.\n";
}

sub do_cmd {
  my ($cmd,@args) = @_;
  my $pty = IO::Pty->new or die "can't make Pty: $!";
  defined (my $child = fork) or die "Can't fork: $!";
  return $pty if $child;

  setsid();
  my $tty = $pty->slave;
  close $pty;

  STDIN->fdopen($tty,"r")      or die "STDIN: $!";
  STDOUT->fdopen($tty,"w")     or die "STDOUT: $!";
  STDERR->fdopen(\*STDOUT,"w") or die "STDERR: $!";
  close $tty;
  $| = 1;
  exec $cmd,@args;
  die "Couldn't exec: $!";
}

#!/usr/bin/perl
# file: change_passwd.pl
# Figure 6.4: Remote password changing script

use strict;
use Net::Telnet;
use Getopt::Long;

use constant DEBUG => 1;

use constant USAGEMSG => <<USAGE;
Usage: change_passwd.pl [options] machine1, machine2, ...
Options: 
        --user  <user>  Login name
        --pass  <pass>  Current password
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
  my $shell = Net::Telnet->new($host);
  $shell->input_log('passwd.log') if DEBUG;
  $shell->errmode('return');

  $shell->login($user,$oldpass) or return warn "$host: ",$shell->errmsg,"\n";

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

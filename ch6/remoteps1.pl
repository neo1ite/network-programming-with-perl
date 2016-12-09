#!/usr/bin/perl
# Figure 6.3: remoteps1.pl logs into a remote host and runs the "ps" command
# file: remoteps1.pl

use strict;
use Net::Telnet;

warn "Change the constants to match a machine you have login access to.\n";

use constant HOST => 'phage.cshl.org';
use constant USER => 'lstein';
use constant PASS => 'xyzzy';

my $telnet = Net::Telnet->new(HOST);
$telnet->login(USER,PASS);
my @lines = $telnet->cmd('ps -ef');
print @lines;

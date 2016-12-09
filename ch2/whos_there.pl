#!/usr/bin/perl
# file: whos_there.pl
# Figure 2.1: A script to open a pipe to the who command

use strict; 
my %who;   # accumulate logins 

open (WHOFH,"who |") or die "Can't open who: $!"; 

while (<WHOFH>) { 
    next unless /^(\S+)/; 
    $who{$1}++; 
} 

foreach (sort {$who{$b}<=>$who{$a}} keys %who) { 
    printf "%10s %d\n",$_,$who{$_}; 
}

close WHOFH or die "Close error: $!";

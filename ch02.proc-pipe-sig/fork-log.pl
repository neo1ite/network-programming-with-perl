#!/usr/bin/perl
use v5.18;

my $child = fork;
die "cannot fork: $!" unless defined $child;
if ($child == 0) {
  open STDOUT, ">log.txt" or die "open() error: $!";
  exec qw(ls -l);
  die "exec error(): $!"; # never here
}
say "this was done after the child process started"

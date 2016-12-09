#!/usr/bin/perl
# file: name_trans.pl
# Figure 3.6: Translating IP addresses into hostnames

use Socket;
my $ADDR_PAT = /^\d+\.\d+\.\d+\.\d+$/;

while (<>) {
  chomp;
  die "$_: Not a valid address" unless /$ADDR_PAT/o;
  my $name = gethostbyaddr(inet_aton($_),AF_INET);
  $name ||= '?';
  print "$_ => $name\n";
}

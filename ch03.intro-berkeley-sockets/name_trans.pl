#!/usr/bin/perl
use Socket;
my $ADDR_PAT = qr'^(?:\d\.){3}\d$'o;
while (<>) {
   chomp;
   die "$_: Not a valid addres" unless /$ADDR_pat/;
   my $name = gethostbyaddr(inet_aton($_), AF_INET);
   $name ||= '?';
   print "$_ => $name\n";
}

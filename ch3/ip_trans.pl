#!/usr/bin/perl
# file: ip_trans.pl
# Figure 3.5: Translating hostnames into IP addresses

use Socket;

while (<>) {
    chomp;
    my $packed_address = gethostbyname($_);
    unless ($packed_address) {
        print "$_ => ?\n";
        next;
    }
    my $dotted_quad    = inet_ntoa($packed_address);
    print "$_ => $dotted_quad\n";
}

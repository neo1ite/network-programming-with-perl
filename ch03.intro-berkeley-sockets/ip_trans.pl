#!/usr/bin/perl
use Socket;
while (<>) {
    chomp;
    my $packed_address = gethostbyname($_);
    unless ($packed_address) {
        print "$_ => ?\n";
        next;
    }
    my $dotted_quad = inet_ntoa($packed_address);
    print "$_ => $dotted_quad\n";
}

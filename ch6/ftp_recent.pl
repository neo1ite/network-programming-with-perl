#!/usr/bin/perl -w
# file: ftp_recent.pl
# Figure 6.1: Downloading a single file with Net::FTP

use Net::FTP;

use constant HOST => 'ftp.perl.org';
use constant DIR  => '/pub/CPAN';
use constant FILE => 'RECENT';

my $ftp = Net::FTP->new(HOST) or die "Couldn't connect: $@\n";
$ftp->login('anonymous')      or die $ftp->message;
$ftp->cwd(DIR)                or die $ftp->message;
$ftp->get(FILE)               or die $ftp->message;
$ftp->quit;

warn "File retrieved successfully.\n";

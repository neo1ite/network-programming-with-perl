#!/usr/bin/perl
# file: mirror_rfc.pl
# Figure 9.5: Mirror RFCs from www.faqs.org

use strict;
use LWP;

use constant RFCS => 'http://www.faqs.org/rfcs/';

die "Usage: mirror_rfc.pl rfc1 rfc2...\n" unless @ARGV;

my $ua       = LWP::UserAgent->new;
my $newagent = 'mirror_rfc/1.0 (' . $ua->agent .')';
$ua->agent($newagent);

while (defined (my $rfc = shift)) {
  warn "$rfc: invalid RFC number\n" && next unless $rfc =~ /^\d+$/;
  my $filename = "rfc$rfc.html";
  my $url = RFCS . $filename;

  my $response = $ua->mirror($url,$filename);
  print "RFC $rfc: ",$response->message,"\n";
}


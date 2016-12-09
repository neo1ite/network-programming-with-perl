#!/usr/bin/perl
# file: get_rfc.pl
# Figure 9.4: Fetch RFCs from www.faqs.org

use strict;
use LWP;

use constant RFCS => 'http://www.faqs.org/rfcs/';

die "Usage: get_rfc.pl rfc1 rfc2...\n" unless @ARGV;

my $ua       = LWP::UserAgent->new;
my $newagent = 'get_rfc/1.0 (' . $ua->agent .')';
$ua->agent($newagent);

while (defined (my $rfc = shift)) {
  warn "$rfc: invalid RFC number\n" && next unless $rfc =~ /^\d+$/;

  my $request = HTTP::Request->new(GET => RFCS . "rfc$rfc.html");
  my $response = $ua->request($request);

  if ($response->is_success) {
    print $response->content;
  } else {
    warn "RFC $rfc: ",$response->message,"\n";
  }
}

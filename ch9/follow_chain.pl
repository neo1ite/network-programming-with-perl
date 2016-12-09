#!/usr/bin/perl
# file follow_chain.pl
# Figure 9.3: The follow_chain.pl script tracks redirects

use strict;
use LWP;

my $url = shift;

my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(HEAD => $url);

my $response = $agent->request($request);
$response->is_success or die "$url: ",$response->message,"\n";

my @urls;
for (my $r = $response; defined $r; $r = $r->previous) {
  unshift @urls,$r->request->uri . ' (' . $r->status_line .')';
}

print "Response chain:\n\t",join("\n\t-> ",@urls),"\n";;


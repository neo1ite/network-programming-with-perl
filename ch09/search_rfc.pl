#!/usr/bin/perl
# file: search_rfc.pl
# Figure 9.8: Search for RFCs by simulating a form POSTing

use strict;
use LWP;
use URI::Escape;

use constant RFC_SEARCH  => 'http://www.faqs.org/cgi-bin/rfcsearch';
use constant RFC_REFERER => 'http://www.faqs.org/rfcs/';

die "Usage: rfc_search.pl term1 term2...\n" unless @ARGV;

my $ua       = LWP::UserAgent->new;
my $newagent = 'search_rfc/1.0 (' . $ua->agent .')';
$ua->agent($newagent);

my $search_terms = "@ARGV";
my $query_string = uri_escape("query=$search_terms&archive=rfcindex");

my $request = HTTP::Request->new(POST => RFC_SEARCH);
$request->content($query_string);
$request->referer(RFC_REFERER);

my $response = $ua->request($request);
die $response->message unless $response->is_success;

my $content = $response->content;
while ($content =~ /(RFC \d+).*<STRONG>(.+)<\/STRONG>/g) {
  print "$1\t$2\n";
}

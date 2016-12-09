#!/usr/bin/perl
# file: search_rfc2.pl
# Figure 9.10: An improved version of search_rfc.pl

use strict;
use LWP;
use HTTP::Request::Common;

use constant RFC_SEARCH  => 'http://www.faqs.org/cgi-bin/rfcsearch';
use constant RFC_REFERER => 'http://www.faqs.org/rfcs/';

die "Usage: rfc_search2.pl term1 term2...\n" unless @ARGV;

my $ua       = LWP::UserAgent->new;
my $newagent = 'search_rfc/1.0 (' . $ua->agent .')';
$ua->agent($newagent);

my $search_terms = "@ARGV";

my $request = POST ( RFC_SEARCH,
                     Content => [ query   => $search_terms,
                                  archive => 'rfcindex'
                                 ],
                     Referer => RFC_REFERER
                   );

my $response = $ua->request($request);
die $response->message unless $response->is_success;

my $content = $response->content;
while ($content =~ /(RFC \d+).*<STRONG>(.+)<\/STRONG>/g) {
  print "$1\t$2\n";
}

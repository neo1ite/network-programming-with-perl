#!/usr/bin/perl
# file get_url.pl
# Figure 9.1: Fetch a URL using LWP's object-oriented interface

use strict;
use LWP;

my $url = shift;

my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);

my $response = $agent->request($request);
$response->is_success or die "$url: ",$response->message,"\n";

print $response->content;

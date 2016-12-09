#!/usr/bin/perl
# file simple_get.pl
# Figure 9.2: Fetch a URL using the LWP::Simple procedural interface

use LWP::Simple;

my $url = shift;
getprint($url);


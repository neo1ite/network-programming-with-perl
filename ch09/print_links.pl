#!/usr/bin/perl
# file: print_links.pl
# Figure 9.19: Extracting links from an HTML document

use strict;
use HTML::Parser;

my $parser = HTML::Parser->new(api_version => 3);
$parser->handler(start => \&print_link, 'tagname,attr');

$parser->parse($_) while <>;
$parser->eof;

sub print_link {
  my ($tagname,$attr) = @_;
  if ($tagname eq 'a') {
    print "link: ",$attr->{href},"\n"
  } elsif ($tagname eq 'img') {
    print "img: ",$attr->{src},"\n";
  }
}

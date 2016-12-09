#!/usr/bin/perl
# file get_url3.pl
# Figure 9.17: Retrieving and formatting HTML

use strict;
use LWP;
use PromptUtil;
use HTML::FormatText;
use HTML::TreeBuilder;

use vars '@ISA';
@ISA = 'LWP::UserAgent';

my $url = shift;

my $agent    = __PACKAGE__->new;
my $request  = HTTP::Request->new(GET => $url);

my $html_tree;  # will hold the parse tree
my $response = $agent->request($request,\&process_document);
$response->is_success or die "$url: ",$response->message,"\n";

# format HTML output
if ($html_tree) {
  $html_tree->eof;
  print HTML::FormatText->new->format($html_tree);
  $html_tree->delete;
}

sub process_document {
  my ($data,$response,$protocol) = @_;
  if ($response->content_type eq 'text/html') {
    $html_tree ||= HTML::TreeBuilder->new;
    $html_tree->parse($data);
  } else {
    print $data;
  }
}

sub get_basic_credentials {
  my ($self,$realm,$uri) = @_;
  print STDERR "Enter username and password for realm \"$realm\".\n";
  print STDERR "username: ";
  chomp (my $name = <>);
  return unless $name;
  my $passwd = get_passwd();
  return ($name,$passwd);
}

#!/usr/bin/perl
# file get_url2.pl
# Figure 9.15: Get URLs with password authorization

use strict;
use LWP;
use PromptUtil;
use vars '@ISA';
@ISA = 'LWP::UserAgent';

my $url = shift;

my $agent    = __PACKAGE__->new;
my $request  = HTTP::Request->new(GET => $url);

my $response = $agent->request($request);
$response->is_success or die "$url: ",$response->message,"\n";

print $response->content;

sub get_basic_credentials {
  my ($self,$realm,$url) = @_;
  print STDERR "Enter username and password for realm \"$realm\".\n";
  print STDERR "username: ";
  chomp (my $name = <>);
  return unless $name;
  my $passwd = get_passwd();
  return ($name,$passwd);
}

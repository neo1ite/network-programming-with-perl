#!/usr/bin/perl
# file: remote_wc.pl
# Figure 9.14: Upload a file to remote word counter script

use strict;
use LWP;
use HTTP::Request::Common;

use constant WC_SCRIPT  => 
  'http://stein.cshl.org/WWW/software/CGI/examples/file_upload.cgi';

my $file = shift or die "Usage: remote_wc.pl file\n";

my $ua       = LWP::UserAgent->new;
my $newagent = 'remote_wc/1.0 (' . $ua->agent .')';
$ua->agent($newagent);

my $request = POST( WC_SCRIPT,
                    Content_Type => 'form-data',
                    Content => [ 
                                count        => 'count lines',
                                count        => 'count words',
                                count        => 'count characters',
                                '.cgifields' => 'count',
                                submit       => 'Process File',
                                filename     => [ $file ],
                               ]
                  );

my $response = $ua->request($request);
die $response->message unless $response->is_success;

my $content = $response->content;
my ($lines,$words,$characters) = 
  $content =~ m!Lines:.+?(\d+).+?Words:.+?(\d+).+?Characters:.+?(\d+)!;

print "lines = $lines; words = $words; characters = $characters\n";

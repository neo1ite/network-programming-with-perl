#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl} -w
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
# file: search_rfc3.pl
# Figure 9.20: Retrieving RFCs from www.faqs.org by parsing HTML

use strict;
use LWP;
use HTTP::Request::Common;
use HTML::Parser;

use constant RFC_SEARCH  => 'http://www.faqs.org/cgi-bin/rfcsearch';
use constant RFC_REFERER => 'http://www.faqs.org/rfcs/';

die "Usage: rfc_search2.pl term1 term2...\n" unless @ARGV;

my $ua       = LWP::UserAgent->new;
my $newagent = 'search_rfc/1.0 (' . $ua->agent .')';
$ua->agent($newagent);

my $search_terms = "@ARGV";

my $request = POST ( RFC_SEARCH,
                     [ query   => $search_terms,
                       archive => 'rfcindex'
                     ],
                     Referer => RFC_REFERER
                   );

my $parser = HTML::Parser->new(api_version => 3);
$parser->handler(start => \&start, 'self,tagname');

my $response = $ua->request($request,sub {$parser->parse(shift)} );
$parser->eof;

die $response->message unless $response->is_success;

# parser callbacks
sub start {
  my ($parser,$tag) = @_;
  $parser->{last_tag} = $tag;
  return unless $tag eq 'ol';
  $parser->handler(text => \&extract, 'self,dtext');
  $parser->handler(end  => \&end, 'self,tagname');
}

sub end {
  my ($parser,$tag) = @_;
  undef $parser->{last_tag};
  return unless $tag eq 'ol';
  $parser->handler(text => undef);
  $parser->handler(end  => undef);
}

sub extract {
  my ($parser,$text) = @_;
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;
  print $text,"\t" if $parser->{last_tag} eq 'a';
  print $text,"\n" if $parser->{last_tag} eq 'strong';
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

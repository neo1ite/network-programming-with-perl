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
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

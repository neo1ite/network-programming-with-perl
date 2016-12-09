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
# file follow_chain.pl
# Figure 9.3: The follow_chain.pl script tracks redirects

use strict;
use LWP;

my $url = shift;

my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(HEAD => $url);

my $response = $agent->request($request);
$response->is_success or die "$url: ",$response->message,"\n";

my @urls;
for (my $r = $response; defined $r; $r = $r->previous) {
  unshift @urls,$r->request->uri . ' (' . $r->status_line .')';
}

print "Response chain:\n\t",join("\n\t-> ",@urls),"\n";;

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

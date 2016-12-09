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
# file: mirror_rfc.pl
# Figure 9.5: Mirror RFCs from www.faqs.org

use strict;
use LWP;

use constant RFCS => 'http://www.faqs.org/rfcs/';

die "Usage: mirror_rfc.pl rfc1 rfc2...\n" unless @ARGV;

my $ua       = LWP::UserAgent->new;
my $newagent = 'mirror_rfc/1.0 (' . $ua->agent .')';
$ua->agent($newagent);

while (defined (my $rfc = shift)) {
  warn "$rfc: invalid RFC number\n" && next unless $rfc =~ /^\d+$/;
  my $filename = "rfc$rfc.html";
  my $url = RFCS . $filename;

  my $response = $ua->mirror($url,$filename);
  print "RFC $rfc: ",$response->message,"\n";
}

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

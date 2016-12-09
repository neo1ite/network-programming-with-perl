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
# file: web_fetch.pl
# Figure 5.5: Simple web page fetcher

use strict;
use IO::Socket qw(:DEFAULT :crlf);
$/ = CRLF . CRLF;
my $data;

my $url = shift or die "Usage: web_fetch.pl <URL>\n";

my ($host,$path) = $url=~m!^http://([^/]+)(/[^\#]*)! 
  or die "Invalid URL.\n";

my $socket = IO::Socket::INET->new(PeerAddr => $host, PeerPort => 'http(80)')
  or die "Can't connect: $!";

print $socket "GET $path HTTP/1.0",CRLF,CRLF;

my $header = <$socket>;    # read the header
$header =~ s/$CRLF/\n/g;   # replace CRLF with logical newline
print $header;

print $data while read($socket,$data,1024) > 0;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

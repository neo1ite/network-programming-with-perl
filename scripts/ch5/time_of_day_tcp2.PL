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
# file: time_of_day_tcp2.pl
# Figure 5.1 Time of day client using IO::Socket

use strict;
use IO::Socket qw(:DEFAULT :crlf);

my $host = shift || 'localhost';
$/ = CRLF;

my $socket = IO::Socket::INET->new("$host:daytime") 
    or die "Can't connect to daytime service at $host: $!\n";

chomp(my $time = $socket->getline);
print $time,"\n";
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

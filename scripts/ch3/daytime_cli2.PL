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
# file daytime_cli2.pl
# Figure 3.7: Daytime client, using symbolic host and service names

use strict;
use Socket;

use constant DEFAULT_ADDR => '127.0.0.1';

my $packed_addr  = gethostbyname(shift || DEFAULT_ADDR) or die "Can't look up host: $!";
my $protocol     = getprotobyname('tcp');
my $port         = getservbyname('daytime','tcp') or die "Can't look up port: $!";
my $destination  = sockaddr_in($port,$packed_addr);

socket(SOCK,PF_INET,SOCK_STREAM,$protocol)  or die "Can't make socket: $!";
connect(SOCK,$destination)                  or die "Can't connect: $!";

print <SOCK>;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

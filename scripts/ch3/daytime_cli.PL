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
# file: daytime_cli.pl
# Figure 3.4: A Daytime Client

use strict;
use Socket;

use constant DEFAULT_ADDR => '127.0.0.1';
use constant PORT         => 13;
use constant IPPROTO_TCP  => 6;

my $address = shift || DEFAULT_ADDR;
my $packed_addr = inet_aton($address);
my $destination = sockaddr_in(PORT,$packed_addr);

socket(SOCK,PF_INET,SOCK_STREAM,IPPROTO_TCP) or die "Can't make socket: $!";
connect(SOCK,$destination)                   or die "Can't connect: $!";

print <SOCK>;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

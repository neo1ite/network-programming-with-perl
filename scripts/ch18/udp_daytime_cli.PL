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
# file: udp_daytime.pl
# Figure 18.1: udp_daytime_cli.pl gets the time of day

# usage: udp_daytime_cli.pl [host] [port]

use strict;
use Socket qw(:DEFAULT :crlf);
$/ = CRLF;

use constant DEFAULT_HOST => 'localhost';  # loopback interface
use constant DEFAULT_PORT => 'daytime';    # daytime service
use constant MAX_MSG_LEN  => 100;

my $host = shift || DEFAULT_HOST;
my $port = shift || DEFAULT_PORT;

my $protocol = getprotobyname('udp');
$port        = getservbyname($port,'udp') unless $port =~ /^\d+$/;
my $data;

socket(SOCK, AF_INET, SOCK_DGRAM, $protocol) or die "socket() failed: $!";
my $dest_addr = sockaddr_in($port,inet_aton($host));

send(SOCK,"What time is it?",0,$dest_addr)   or die "send() failed: $!";
recv(SOCK,$data,MAX_MSG_LEN,0)               or die "recv() failed: $!";

chomp($data);
print $data,"\n";

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

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
# file: udp_daytime_cli2.pl
# Figure 18.2: UDP daytime client using IO::Socket

use strict;
use IO::Socket qw(:DEFAULT :crlf);
use constant MAX_MSG_LEN => 100;
$/ = CRLF;
my $data;

my $host = shift || 'localhost';
my $port = shift || 'daytime';

my $sock = IO::Socket::INET->new(Proto    => 'udp',
                                 PeerHost => $host,
                                 PeerPort => $port) or die $@;

$sock->send('Yo!')              or die "send() failed: $!\n";
$sock->recv($data,MAX_MSG_LEN)  or die "recv() failed: $!\n";

chomp($data);
print $data,"\n";

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

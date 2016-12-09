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
# file: tcp_echo_cli2.pl
# Figure 5.2: TCP echo client using IO::Socket

# usage: tcp_echo_cli2.pl [host] [port]

use strict;
use IO::Socket;
my ($bytes_out,$bytes_in) = (0,0);

my $host = shift || 'localhost';
my $port = shift || 'echo';

my $socket = IO::Socket::INET->new("$host:$port") or die $@;

while (defined(my $msg_out = STDIN->getline)) {
    print $socket $msg_out;
    my $msg_in = <$socket>;
    print $msg_in;

    $bytes_out += length($msg_out);
    $bytes_in  += length($msg_in);
}

$socket->close or warn $@;
print STDERR "bytes_sent = $bytes_out, bytes_received = $bytes_in\n";
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

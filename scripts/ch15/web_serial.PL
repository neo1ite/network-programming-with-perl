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
# file: web_serial.pl
# Figure 14.2: The baseline server handles requests serially

use strict;
use IO::Socket;
use Web;

my $port = shift || 8080;
my $socket = IO::Socket::INET->new( LocalPort => $port,
				    Listen    => SOMAXCONN,
				    Reuse     => 1 ) or die "Can't create listen socket: $!";
while (my $c = $socket->accept) {
  handle_connection($c);
  close $c;
}
close $socket;

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

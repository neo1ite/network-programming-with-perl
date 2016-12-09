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
# file: urg_send.pl
# Figure 17.2: Simple urgent data sender client

use strict;
use IO::Socket;

my $HOST = shift || 'localhost';
my $PORT = shift || 2007;

my $socket = IO::Socket::INET->new("$HOST:$PORT") or die "Can't connect: $!";

$SIG{INT}  = sub { print "sending 1 byte of OOB data!\n";
                   send($socket,"!",MSG_OOB);
                 };
$SIG{QUIT} = sub { exit 0 };

for ('aa'..'az') {
  print "sending ",length($_)," bytes of normal data: $_\n";
  syswrite $socket,$_;
  1 until sleep 1;
}

__END__

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

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
# file: localtime_serv.pl
# Figure 22.3: localtime_serv.pl, Daytime server

use IO::Socket;

use constant SOCK_PATH     => '/tmp/localtime';

# get path
my $path = shift || SOCK_PATH;

# handle interrupt key and termination
$SIG{TERM} = $SIG{INT} = sub { exit 0 };

# set umask to be world writable
umask(0111);
my $sock = IO::Socket::UNIX->new( Local => $path,
                                  Type  => SOCK_DGRAM) or die "Socket: $!";
warn "listening on UNIX path $path...\n";

while (1) {
  my $data;
  my $peer = recv($sock,$data,128,0);
  if ($data =~ m!^[a-zA-Z0-9/_-]+$!) { # could be a timezone
    $ENV{TZ} = $data;
  } else {
    delete $ENV{TZ};
  }
  send($sock,scalar localtime,0,$peer) || warn "Couldn't send: $!";
}

END { unlink $path if $path } 
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

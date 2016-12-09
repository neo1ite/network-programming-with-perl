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
# file: wrap_cli.pl
# Figure 22.2: wrap_cli.pl, the text formatting client

use IO::Socket;
use Getopt::Long;

use constant SOCK_PATH     => '/tmp/wrapserv';

my $path;
GetOptions("path=s" => \$path);
$path ||= SOCK_PATH;

my $sock = IO::Socket::UNIX->new($path) or die "Socket: $!";
warn "Connected to $path...\n";

my @lines = <>;  # slurp lines
print $sock @lines;
$sock->shutdown(1);   # close socket for writing
print STDOUT <$sock>; # display the result

__END__

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

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
# file: ftp_recent.pl
# Figure 6.1: Downloading a single file with Net::FTP

use Net::FTP;

use constant HOST => 'ftp.perl.org';
use constant DIR  => '/pub/CPAN';
use constant FILE => 'RECENT';

my $ftp = Net::FTP->new(HOST) or die "Couldn't connect: $@\n";
$ftp->login('anonymous')      or die $ftp->message;
$ftp->cwd(DIR)                or die $ftp->message;
$ftp->get(FILE)               or die $ftp->message;
$ftp->quit;

warn "File retrieved successfully.\n";
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

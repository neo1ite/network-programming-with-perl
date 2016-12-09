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
# file: cat.pl
# Figure 13.1: Reading from STDIN with IO::Getline

use strict;
use IO::Getline;
use IO::Select;

my $s     = IO::Select->new(\*STDIN);
my $stdin = IO::Getline->new(\*STDIN);
my $data;

while ($s->can_read) {
  my $rc = $stdin->getline($data) or last;
  print $data if $rc > 0;
}

die "Read error: ",$stdin->error if $stdin->error;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

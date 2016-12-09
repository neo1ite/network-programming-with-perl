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
# file: write_ten_ph.pl
# Figure 2.5: Intercepting the PIPE signal.

use strict;

my $ok = 1;
$SIG{PIPE} = sub { undef $ok };

open (PIPE,"| read_three.pl") or die "Can't open pipe: $!";
select PIPE; $|=1; select STDOUT;

my $count = 0;
for ($_=1; $ok && $_ <= 10; $_++) {
  warn "Writing line $_\n";
  print PIPE "This is line number $_\n" and $count++;
  sleep 1;
}
close PIPE or die "Can't close pipe: $!";

print "Wrote $count lines of text\n";
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

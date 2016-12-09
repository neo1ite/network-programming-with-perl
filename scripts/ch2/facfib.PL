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
# file: facfib.pl
# Figure 2.2: Using pipe() to create linked filehandles

use strict;
my $arg = shift || 10;

pipe(READER,WRITER) or die "Can't open pipe: $!\n";

if (fork == 0) { # first child writes to WRITER
  close READER;
  select WRITER; $| = 1;
  factorial($arg);
  exit 0;
}

if (fork == 0) { # second child writes to WRITER
  close READER;
  select WRITER; $| = 1;
  my $result = fibonacci($arg);
  exit 0;
}

# parent process closes WRITER and reads from READER
close WRITER;
print while <READER>;

sub factorial {
  my $target = shift;
  for (my $result = 1,my $i = 1; $i <= $target; $i++) {
    print "factorial($i) => ",$result *= $i,"\n";
  }
}

sub fibonacci {
  my $target = shift;
  for (my $result = 1,my $i = 1; $i <= $target; $i++) {
    print "fibonacci($i) => ",$result += $i,"\n";
  }
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

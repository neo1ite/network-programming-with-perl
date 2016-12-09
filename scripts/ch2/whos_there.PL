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
# file: whos_there.pl
# Figure 2.1: A script to open a pipe to the who command

use strict; 
my %who;   # accumulate logins 

open (WHOFH,"who |") or die "Can't open who: $!"; 

while (<WHOFH>) { 
    next unless /^(\S+)/; 
    $who{$1}++; 
} 

foreach (sort {$who{$b}<=>$who{$a}} keys %who) { 
    printf "%10s %d\n",$_,$who{$_}; 
}

close WHOFH or die "Close error: $!";
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

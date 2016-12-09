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
# Figure 6.3: remoteps1.pl logs into a remote host and runs the "ps" command
# file: remoteps1.pl

use strict;
use Net::Telnet;

warn "Change the constants to match a machine you have login access to.\n";

use constant HOST => 'phage.cshl.org';
use constant USER => 'lstein';
use constant PASS => 'xyzzy';

my $telnet = Net::Telnet->new(HOST);
$telnet->login(USER,PASS);
my @lines = $telnet->cmd('ps -ef');
print @lines;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

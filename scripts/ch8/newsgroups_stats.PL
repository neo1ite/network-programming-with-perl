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
# file: newsgroups_stats.pl
# Figure 8.7: Print statistics of newsgroups matching a pattern

use strict;
use Net::NNTP;

my $nntp = Net::NNTP->new() or die "Couldn't connect: $!\n";
print_stats($nntp,$_) while $_ = shift;
$nntp->quit;

sub print_stats {
  my $nntp    = shift;
  my $pattern = shift;
  my $groups  = $nntp->newsgroups($pattern);
  return print "$pattern: No matching newsgroups\n"
    unless $groups && keys %$groups;

  for my $g (sort keys %$groups) {
    my ($articles,$first,$last) = $nntp->group($g);
    printf "%-60s %5d articles\n",$g,$articles;
  }

}

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

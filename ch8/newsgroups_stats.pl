#!/usr/bin/perl
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


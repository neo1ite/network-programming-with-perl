#!/usr/bin/perl
# file: format_html.pl
# Figure 9.16: Render and format HTML

use strict;
use Getopt::Long;
use HTML::TreeBuilder;

my $PS;
GetOptions('postscript' => \$PS) 
  or die "Usage: format_html.pl [--postscript] [file]\n";

my $formatter;
if ($PS) {
  require HTML::FormatPS;
  $formatter = HTML::FormatPS->new(PaperSize=>'Letter');
} else {
  require HTML::FormatText;
  $formatter = HTML::FormatText->new;
}

my $tree = HTML::TreeBuilder->new;
$tree->parse($_) while <>;
$tree->eof;

print $formatter->format($tree);
$tree->delete;

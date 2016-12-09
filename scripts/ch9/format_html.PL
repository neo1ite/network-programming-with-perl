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
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

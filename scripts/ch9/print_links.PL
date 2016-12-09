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
# file: print_links.pl
# Figure 9.19: Extracting links from an HTML document

use strict;
use HTML::Parser;

my $parser = HTML::Parser->new(api_version => 3);
$parser->handler(start => \&print_link, 'tagname,attr');

$parser->parse($_) while <>;
$parser->eof;

sub print_link {
  my ($tagname,$attr) = @_;
  if ($tagname eq 'a') {
    print "link: ",$attr->{href},"\n"
  } elsif ($tagname eq 'img') {
    print "img: ",$attr->{src},"\n";
  }
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

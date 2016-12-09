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
# file: simple_parse.pl
# Figure 7.8: Using MIME::Parser

use strict;
use MIME::Parser;

my $file = shift;
open F,$file or die "can't open $file: $!\n";

# create and configure parser
my $parser = MIME::Parser->new;
$parser->output_dir("/tmp");

# parse the file
my $entity = $parser->parse(\*F);

print "From      = ",$entity->head->get('From');
print "Subject   = ",$entity->head->get('Subject');
print "MIME type = ",$entity->mime_type,"\n";
print "Parts     = ",scalar $entity->parts,"\n";
for my $part ($entity->parts) {
   print "\t",$part->mime_type,"\t",$part->bodyhandle->path,"\n";
}

$entity->purge;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

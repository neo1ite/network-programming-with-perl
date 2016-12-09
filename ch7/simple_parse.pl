#!/usr/bin/perl
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

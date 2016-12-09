#!/usr/bin/perl -T
# file: pop_fetch.pl
# Figure 8.3: The pop_fetch.pl script

use strict;
use lib '.';

use PopParser;
use PromptUtil;
use Carp qw(carp confess);

use constant HTML_VIEWER  => 'lynx %s';
use constant IMAGE_VIEWER => 'xv -';
use constant MP3_PLAYER   => 'mpg123 -';
use constant WAV_PLAYER   => 'wavplay %s';
use constant SND_PLAYER   => 'aplay %s';

$ENV{PATH} = '/bin:/usr/bin:/usr/X11/bin:/usr/local/bin';
delete $ENV{$_} foreach qw/ENV IFS BASH_ENV CDPATH/;

my($username,$host) = shift =~ /([\w.-]+)@([\w.-]+)/;
$username or die <<'USAGE';
Usage: pop_parse.pl username@pop.server
USAGE
  ;

my $entity;
$SIG{INT} = sub { exit 0 };

my $pop = PopParser->new($host) or die "Connect to host: $!\n";
my $passwd = get_passwd($username,$host);

my $message_count = $pop->apop($username => $passwd) 
                      || $pop->login($username => $passwd)
                      or die "Can't log in: ",$pop->message,"\n";

print "You have ",$message_count+=0," messages in your inbox.\n\n";
for my $msgnum (1..$message_count) {
  print "MESSAGE $msgnum of $message_count\n";

  print_header($pop->top($msgnum));
  if (prompt("\nRead it (y/n)",'y') eq 'y') {
    next unless $entity = $pop->get($msgnum);
    display_entity($entity);
    $entity->purge;
  }

  if (prompt('Delete this message (y/n)','n') eq 'y') {
    $pop->delete($msgnum);
  }
} continue { print "\n" }

# print a line that summarizes the header
sub print_header {
  my $header = join '',@{shift()};
  $header =~ s/\n\s+/ /gm;
  my (%fields) = $header =~ /([\w-]+):\s+(.+)$/mg;
  print join "\t",@fields{'Date','From','Subject'},"\n";
}

# view a message
sub display_entity {
  my $entity = shift;

  # first handle the head
  my $head   = $entity->head;
  $head->print if $head->get('From');  # print whole header if top level

  # now handle the body
  print "\n";

  # A multipart message
  if ($entity->is_multipart) {
    handle_multipart($entity);
  } else {  # A single-part message
    display_part($entity);
  }
}

# called to process all the parts of a multipart entity
sub handle_multipart {
  my $entity = shift;
  my @parts        = $entity->parts;

  # separate text/plain parts from the others
  my @text         = grep $_->mime_type eq 'text/plain',@parts;
  my @attachments  = grep $_->mime_type ne 'text/plain',@parts;

  # display all text/plain parts
  display_part($_) foreach (@text);

  return unless my $atcount = @attachments;

  my $prompt = $atcount > 1 ? "\nThis message has $atcount attachments.  View them (y/n)?"
                            : "\nThis message has an attachment.  View it (y/n)?";
  return unless prompt($prompt,'y') eq 'y';

  for (my $i=0;$i<@attachments;$i++) {
    print "\tATTACHMENT ",$i+1," of ".@attachments,"\n";
    display_entity($attachments[$i])
  }
}

# view the content of a message part
sub display_part {
  my $part = shift;

  my $head             = $part->head;
  my $type             = $head->mime_type;
  my $description      = $head->get('Content-Description');
  my ($default_name)   = $head->get('Content-Disposition') =~ /filename="([^\"]+)"/;
  my $body             = $part->bodyhandle;

  # text/plain type
  return $body->print if $type eq 'text/plain';

  # otherwise not plain text
  my $viewer = get_viewer($type);
  my $prompt = $viewer ? "\n<v>iew, <s>ave or <n>ext" : "\n<s>ave or <n>ext";

  print "\tType: $type.\n";
  print "\tDescription: $description\n" if $description;
  print "\tFilename: $default_name\n"   if $default_name;

  while ( (my $action = prompt ($prompt,'s')) =~ /[sv]/) {
    save_body($body,$default_name)  if $action eq 's';
    display_body($body,$viewer)     if $action eq 'v';
  }

}

# called to save an attachment to disk
sub save_body {
  my($body,$default_name) = @_;
  my $open_ok = 0;
  my $path;
  while (!$open_ok) {
    $path = prompt('Save to file or <n>ext ',"./$default_name");
    return if $path eq 'n';
    warn "Bad path name, try again.\n" and next if $path =~ m!^/|(?:^|/)\.\./!;
    warn "Bad path name, try again.\n" and next unless $path =~ m!^([/\w._-]+)$!;
    $open_ok = open(F,">$1");
    warn "Couldn't open $path: $!\n" unless $open_ok;
  }
  $body->print(\*F) && print "Written to $path\n";
  close F || warn "close error on $path: $!\n";
}

# called to view the body of an attachment
sub display_body {
  my($body,$viewer) = @_;

  my $file = $body->path;
  if ($file && $viewer =~ s/%s/$file/g) {   # have viewer open directly
    system("$viewer $file") && return warn "Couldn't launch viewer: $!\n";
  } else {       # ask viewer to open from STDIN
    local $SIG{PIPE}='IGNORE';
    open(V,"| $viewer")     || return warn "Couldn't launch viewer: $!\n";
    $body->print(\*V);
    close V;
  }
}

# look up a viewer given the MIME type
sub get_viewer {
  my $type = shift;
  return HTML_VIEWER   if $type eq 'text/html';
  return IMAGE_VIEWER  if $type =~ m!^image/!;
  return MP3_PLAYER    if $type =~ m!^audio/(x-)?mpeg!;
  return SND_PLAYER    if $type =~ m!^audio/!;
  return;
}

END {  
  $entity->purge if defined $entity;
}

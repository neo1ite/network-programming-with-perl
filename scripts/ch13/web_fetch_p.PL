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
# file: web_fetch_p.pl
# Figure 13.9: The web_fetch script uses nonblocking connects to parallelize URL fetches

use strict;
use HTTPFetch;
use IO::Socket;
use IO::Select;

my %CONNECTIONS;  # map socket => object

# create two IO::Select objects to handle writing & reading
my $readers = IO::Select->new;
my $writers = IO::Select->new;

# create the connections from list of urls on command line
while (my $url = shift) {
  next unless my $object = HTTPFetch->new($url);
  $CONNECTIONS{$object->socket} = $object;  # remember its socket
  $writers->add($object->socket);           # monitor it for writing
}

while (my ($readable,$writable) = IO::Select->select($readers,$writers)) {

  foreach (@$writable) {        # handle is ready for writing
    my $obj = $CONNECTIONS{$_};       # recover the HTTP object
    my $result = $obj->send_request;  # try to send the request
    $readers->add($_) if $result;     # send successful, so monitor for reading
    $writers->remove($_);             # and remove from list monitored for writing
  }

  foreach (@$readable) {        # handle is ready for reading
    my $obj = $CONNECTIONS{$_};           # recover the HTTP object
    my $result = $obj->read;              # read some data
    unless ($result) {                    # remove if some error occurred
      $readers->remove($_);  
      delete $CONNECTIONS{$_};
    }
  }

  last unless $readers->count or $writers->count;  # quit when no more to do
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

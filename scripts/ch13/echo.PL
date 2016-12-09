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
# file: echo.pl
# Figure 13.3: An echo server that uses IO::SessionSet

use strict;
use IO::SessionSet;

use constant PORT => 12000;

my $listen_socket = IO::Socket::INET->new(LocalPort => PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die "Can't create a listening socket: $@" unless $listen_socket;
my $session_set = IO::SessionSet->new($listen_socket);

warn "Listening for connections...\n";

while (1) {
  my @ready = $session_set->wait;

  for my $session (@ready) {
    my $data;
    if (my $rc = $session->read($data,4096)) {
      $session->write($data) if $rc > 0;
    } else {
      $session->close;
    }
  }

}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

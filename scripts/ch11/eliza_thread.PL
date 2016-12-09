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
# file: eliza_thread.pl
# Figure 11.1: Multithreaded psychiatrist server

use strict;
use IO::Socket;
use Thread;
use Chatbot::Eliza::Server;

use constant PORT => 12000;
my $listen_socket = IO::Socket::INET->new(LocalPort => PORT,
                                          Listen    => 20,
                                          Proto     => 'tcp',
                                          Reuse     => 1);
die $@ unless $listen_socket;

warn "Listening for connections...\n";

while (my $connection = $listen_socket->accept) {
  Thread->new(\&interact,$connection);
}

sub interact {
  my $handle = shift;
  Thread->self->detach;
  Chatbot::Eliza::Server->new->command_interface($handle,$handle);
  $handle->close();
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

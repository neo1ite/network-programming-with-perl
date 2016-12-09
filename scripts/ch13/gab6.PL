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
# file: gab6.pl
# Figure 13.7: Telnet-style client using nonblocking I/O

# usage: gab6.pl [host] [port]

use strict;
use IO::Socket;
use IO::SessionSet;
$IO::SessionSet::DEBUG=0;

my $host = shift or die "Usage gab6.pl host [port]\n";
my $port = shift || 'echo';

my $socket = IO::Socket::INET->new("$host:$port") or die $@;
my $set = IO::SessionSet->new or die;

my $connection = $set->add($socket);
my $stdin      = $set->add(\*STDIN);
my $stdout     = $set->add(\*STDOUT,1);

$stdout->set_choke(sub {
                     my ($session,$do_choke) = @_;
                     $connection->readable(!$do_choke);
                   });
$connection->set_choke(sub {
                         my ($session,$do_choke) = @_;
                         $stdin->readable(!$do_choke);
                       });

my $data;
while ($set->sessions) {

  my @ready = $set->wait();

  foreach (@ready) {

    if ($_ eq $connection) {
      if (my $bytes = $connection->read($data,1024)) {
        $stdout->write($data) if $bytes > 0;
      } else {
        warn "connection terminated by remote host\n";
        $connection->close;
        $stdout->close;
        $stdin->close;
      }
    }

    if ($_ eq $stdin) {
      if (my $bytes = $stdin->read($data,1024)) {
        $connection->write($data) if $bytes > 0;
      } else {
        $connection->handle->shutdown(1);
      }
    }

  }
}

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

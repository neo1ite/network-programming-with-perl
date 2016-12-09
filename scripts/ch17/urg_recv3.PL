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
# file: urg_recv3.pl
# Figure 17.4: An urgent data receiver implemented using select()

use strict;
use IO::Socket;
use IO::Select;

my $PORT = shift || 2007;

my $listen = IO::Socket::INET->new( Listen    => 15,
                                    LocalPort => $PORT,
                                    Reuse     => 1) || die "Can't listen: $!";
warn "Listening on port $PORT...\n";

my $ok_to_read_oob = 1;
my $sock = $listen->accept;

my $reader = IO::Select->new($sock);  # to monitor for normal data
my $except = IO::Select->new;         # to monitor for urgent data

while (1) {
  my $data;

  $except->add($sock) if $ok_to_read_oob; 

  my ($has_regular,undef,$has_urgent) = IO::Select->select($reader,undef,$except);

  if (@$has_urgent) {
    my $r = recv($sock,$data,100,MSG_OOB);
    print $r ? "got ".length($data)." bytes of urgent data: $data\n"
             : "recv() error: $!\n";
    $ok_to_read_oob = 0;
    $except->remove($sock);
  }

  if (@$has_regular) {
    last unless sysread $sock,$data,1024;
    print "got ",length $data," bytes of normal data: $data\n";
    $ok_to_read_oob++;
  }

}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

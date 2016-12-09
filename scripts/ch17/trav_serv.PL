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
# file: trav_serv.pl
# Figure 17.6: Travesty server

use strict;
use POSIX 'WNOHANG';
use IO::Socket qw(:DEFAULT :crlf);
use Fcntl 'F_SETOWN';
use Text::Travesty;
use IO::Getline;
use IO::Sockatmark;
use constant DEBUG => 1;

my ($gl,$line);

$SIG{CHLD} = sub { 1 while waitpid(-1,WNOHANG) > 0 };
$SIG{URG} = 'IGNORE';

my $PORT = shift || 2007;
my $listen = IO::Socket::INET->new( Listen    => 15,
                                    LocalPort => $PORT,
                                    Reuse     => 1) or die "Can't listen: $!";
warn "Listening on port $PORT...\n";

while (my $sock = $listen->accept) {
  my $child = fork;
  die "Can't fork: $!"     unless defined $child;
  unless ($child > 0) {
    handle_connection($sock);
    exit 0; # child never returns
  }
  close $sock;
}

# per-connection code
sub handle_connection {
  my $sock = shift;
  warn "client connecting...\n" if DEBUG;

  fcntl($sock,F_SETOWN,$$) or die "Can't set owner: $!";

  local $/ = "$CRLF";
  my $travesty = Text::Travesty->new; 
  $gl = IO::Getline->new($sock);
  $gl->blocking(1);   # turn blocking mode back on

  syswrite($sock,"100 Travesty server version 1.0$CRLF");
  my $command;
  while (my $result = $gl->getline($command)) {
    warn "command  = $command" if DEBUG;
    chomp $command;

    analyze_file ($travesty),next           if $command eq 'DATA';
    reset_travesty($travesty),next          if $command eq 'RESET';
    make_travesty($travesty,$1),next        if $command =~ /^GENERATE\s+(\d+)$/;
    $gl->syswrite("204 goodbye$CRLF"),last  if $command eq 'BYE';
    $gl->syswrite("500 unknown command$CRLF");
  }
  warn "client exiting...\n" if DEBUG;
  close $sock;
}

# analyze a file
sub analyze_file {
  my $travesty = shift;
  $travesty->reset;
  $gl->syswrite("201 Upload data; end with \".\" on a line by itself.$CRLF");
  my $line;
  eval {
    local $SIG{URG} = sub { do_urgent(); die };
    while (my $result = $gl->getline($line)) {
      chomp $line;
      last if $line eq '.';
      $travesty->add($line);
    }
  };
  $gl->syswrite("202 processed ".$travesty->words()." words$CRLF");
}

# regurgitate a file
sub make_travesty {
  my ($travesty,$words) = @_;
  $gl->syswrite("500 no data analyzed$CRLF"),return 
    unless $travesty->words;

  $gl->syswrite("203 travesty follows$CRLF");
  my $abort = 0;
  eval {
    local $SIG{URG} = sub {do_urgent(); $abort++; die };
    while ($words > 0) {
      my $w     = $words > 500 ? 500 : $words;
      my $text = $travesty->pretty_text($w);
      $text =~ s/\n/$CRLF/g;
      $gl->syswrite($text);
      $words -= $w;
    }
    $gl->syswrite(".$CRLF");
  };
  if ($abort) {
    warn "make_travesty() aborted\n" if DEBUG;
    $gl->send('!',MSG_OOB);
  } 
}

sub reset_travesty {
  my $t = shift;
  $t->reset;
  $gl->syswrite("205 travesty reset$CRLF");
}

sub do_urgent {
  my $data;
  warn "do_urgent()" if DEBUG;
  my $sock = $gl->handle;
  # read up to the mark, tossing data
  until ($sock->atmark) {
    my $n = sysread($sock,$data,1024);
    warn "discarding $n bytes\n" if DEBUG;
  }

  # read the OOB data and toss it
  warn "reading 1 byte of urgent data\n" if DEBUG;
  recv($sock,$data,1,MSG_OOB);

  # send urgent data back to sender
  $gl->flush;  # clear the data buffer
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

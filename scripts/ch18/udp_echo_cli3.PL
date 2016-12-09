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
# file: udp_echo_cli3.pl
# Figure 18.7: This script detects duplicate and misordered UDP messages

# usage: udp_echo_cli3.pl [host] [port]

use strict;
use IO::Socket;
use IO::Select;
use IO::Getline;

use constant MAX_MSG_LEN  => 5000;
use constant TIMEOUT      => 2;
use constant MAX_RETRIES  => 5;

my %PENDING;  # hash of requests indexed by sequence number
use constant REQUEST   => 0;   # with these two fields
use constant TRIES     => 1;

# keep track of outgoing and incoming sequence numbers
my $seqout  = 0;
my $seqin   = 0;

my $host = shift || 'localhost';
my $port = shift || 'echo';

my $sock = IO::Socket::INET->new(Proto=>'udp',PeerAddr=>"$host:$port")
  or die $@;

my $select = IO::Select->new($sock,\*STDIN);
my $stdin  = IO::Getline->new(\*STDIN);

LOOP:
while (1) {
  my @ready = $select->can_read(TIMEOUT);

  for my $handle (@ready) {
    if ($handle eq \*STDIN) {
      my $length = $stdin->getline($_) or last LOOP;
      next unless $length > 0;
      chomp;
      send_message($seqout++,$_);
    }

    if ($handle eq $sock) {
      my $data;
      $sock->recv($data,MAX_MSG_LEN) or die "recv(): $!\n";
      receive_message($data);
    }

  }

  # handle any leftover messages on timeout events
  do_retries() unless @ready;
}

sub send_message {
  my ($sequence,$msg) = @_;

  # send the message
  $sock->send("$sequence: $msg") or die "send(): $!\n";

  # mark this as pending
  $PENDING{$sequence}[REQUEST] = $msg;
  $PENDING{$sequence}[TRIES]++;
}

sub receive_message {
  my $message = shift;
  my ($sequence,$msg) = $message =~ /^(\d+): (.*)/
    or return warn "bad format message '$message'!\n";

  # did we ask for this?
  unless ($PENDING{$sequence}) {
    warn "Discarding duplicate message seqno = $sequence\n";
    return;
  }

  # warn about out of order messages
  warn "Out of order message seqno = $sequence\n" if $sequence < $seqin;

  # print result
  print $PENDING{$sequence}[REQUEST],' => ',$msg,"\n";

  # remember last sequence number, and remove message from pending
  $seqin = $sequence;
  delete $PENDING{$sequence};
}

sub do_retries {
  for my $seq (keys %PENDING) {
    if ($PENDING{$seq}[TRIES] >= MAX_RETRIES) {
      warn "$seq: too many retries. Giving up.\n";
      delete $PENDING{$seq};
      next;
    }
    warn "$seq: retrying...\n";
    send_message($seq,$PENDING{$seq}[REQUEST]); 
  }
}

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

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
# file: trav_cli.pl
# Figure 17.7: Travesty Client

use strict;
use Fcntl 'F_SETOWN';
use IO::Socket qw(:DEFAULT :crlf);
use IO::File;
use IO::Getline;
use IO::Sockatmark;
use constant DEBUG => 1;
$| = 1;

my $HOST = shift || 'localhost';
my $PORT = shift || 2007;
my ($gl,$quit_now,$line); 

$SIG{QUIT} = sub { exit 0 };
$SIG{INT}  = sub { ++$quit_now >= 2 && exit 0; warn "Press ^C again to exit\n" };
$SIG{URG} = \&do_urgent;

my $sock = IO::Socket::INET->new("$HOST:$PORT") or die "Can't connect";

# set the owner for the socket so that we get sigURG
fcntl($sock,F_SETOWN,$$) or die "Can't set owner: $!";

$gl = IO::Getline->new($sock);
$gl->blocking(1);    # turn blocking back on

$gl->getline($line) or die "Unexpected close of server socket\n";
$line =~ /^100/     or die "Didn't get welcome banner from server.\n";

print "> ";

while (<>) {  # read commands from stdin
  chomp;
  next unless my ($command,$args) = /^(\w+)\s*(.*)/;
  do_analyze($args),next   if $command =~ /^analyze$/i;
  do_reset($args),next     if $command =~ /^reset$/i;
  do_get($args),next       if $command =~ /^generate$/i;
  do_bye($args),last       if $command =~ /^(good)?bye|quit$/i;
  print_usage();
} continue {
  $quit_now = 0;
  print "> ";
}
$gl->close;

sub do_analyze {
  my $file = shift;

  my $fh = IO::File->new($file);
  warn "Couldn't open $file: $!\n" and return unless $fh;

  $gl->syswrite("DATA$CRLF");
  return unless $gl->getline($line);
  warn $line and return  unless $line =~ /^201/;

  print "analyzing...";
  my $abort = 0;
  eval {
    local $SIG{INT} = sub { print "interrupted!..."; $abort++; die; };
    my $data;
    while (<$fh>) {
      chomp;
      next unless /\w+/;  # avoid blank lines and those containing a "." alone
      $gl->syswrite("$_$CRLF");
    }
    $gl->syswrite(".$CRLF");
  };

  $gl->send("!",MSG_OOB) if $abort;
  return unless $gl->getline($line);
  warn $line and return unless $line =~ /^202 \D*(\d+) words/;
  print "processed $1 words\n";
}

sub do_reset { 
  my $line;
  $gl->syswrite("RESET$CRLF");
  $gl->getline($line) or die "unexpected close of socket\n";
  warn $line and return unless $line =~ /^205/;
  print "reset successful\n";
}

sub do_bye   { $gl->syswrite("BYE$CRLF")   }

sub do_get   {
  my $words = shift;
  warn "Argument to generate must be numeric\n" and return
    unless $words =~ /^\d+$/;
  $gl->syswrite("GENERATE $words$CRLF");
  $gl->getline($line) or die "unexpected close of socket\n";
  warn $line and return unless $line =~ /^203/;
  my $abort = 0;
  eval {
    local $/ = "$CRLF";
    local $SIG{INT}  = sub { $abort++; die };
    while ($gl->getline($line)) {
      chomp $line;
      last if $line eq '.';
      print $line,"\n";
    }
  };
  if ($abort) { 
    $gl->send("!",MSG_OOB);
    print "\n[interrupted]\n";
  }
}

sub do_urgent {
  my $data;
  warn "do_urgent()" if DEBUG;
  my $sock = $gl->handle;
  # read up to the mark, tossing data
  until ($sock->atmark) {
    my $n = sysread($sock,$data,1024);
    warn "discarding $n bytes of data\n" if DEBUG;
  }
  # read the OOB data and toss it
  warn "reading 1 byte of urgent data\n" if DEBUG;
  recv($sock,$data,1,MSG_OOB);
  $gl->flush;
}

sub print_usage {
  print <<END;
commands: 
     analyze   /path/to/file
     generate NNNN
     reset
     goodbye
END
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

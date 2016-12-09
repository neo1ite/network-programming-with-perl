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
# file: tcp_echo_serv1.pl
# Figure 4.2: A TCP Echo Server

# usage: tcp_echo_serv1.pl [port]

use strict;
use Socket;
use IO::Handle;
use constant MY_ECHO_PORT => 2007;

my ($bytes_out,$bytes_in) = (0,0);

my $port     = shift || MY_ECHO_PORT;
my $protocol = getprotobyname('tcp');

$SIG{'INT'} = sub { 
    print STDERR "bytes_sent = $bytes_out, bytes_received = $bytes_in\n";
    exit 0;
};

socket(SOCK, AF_INET, SOCK_STREAM, $protocol) or die "socket() failed: $!";
setsockopt(SOCK,SOL_SOCKET,SO_REUSEADDR,1)    or die "Can't set SO_REUSADDR: $!" ;

my $my_addr = sockaddr_in($port,INADDR_ANY);
bind(SOCK,$my_addr)    or die "bind() failed: $!";
listen(SOCK,SOMAXCONN) or die "listen() failed: $!";

warn "waiting for incoming connections on port $port...\n";

while (1) {
  next unless my $remote_addr = accept(SESSION,SOCK);
  my ($port,$hisaddr) = sockaddr_in($remote_addr);
  warn "Connection from [",inet_ntoa($hisaddr),",$port]\n";

  SESSION->autoflush(1);
  while (<SESSION>) {
    $bytes_in  += length($_);       
    chomp;
    my $msg_out = (scalar reverse $_) . "\n";
    print SESSION $msg_out;
    $bytes_out += length($msg_out);
  }
  warn "Connection from [",inet_ntoa($hisaddr),",$port] finished\n";
  close SESSION;

}

close SOCK;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

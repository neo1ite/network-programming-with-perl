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
# file: chat_client.pl
# Figure 21.10/Appendix A: Internet chat client using multicast

use strict;
use IO::Socket;
use IO::Select;
use Sys::Hostname;
use IO::Socket::Multicast;
use ChatObjects::ChatCodes;

$SIG{INT} = $SIG{TERM} = sub { exit 0 };
my $nickname;

# callbacks
my %COMMANDS = ( 
                channels  => sub { do_send(LIST_CHANNELS)      },
                join      => sub { do_send(JOIN_REQ,shift)     },
                part      => sub { do_send(PART_REQ,shift)     },
                users     => sub { do_send(LIST_USERS)         },
                public    => sub { do_send(SEND_PUBLIC,shift)  },
                private   => sub { do_send(SEND_PRIVATE,shift) },
                login     => sub { $nickname = do_login()      },
                quit      => sub { undef },
               );
my %MESSAGES = (
                ERROR()        => \&error,
                LOGIN_ACK()    => \&login_ack,
                JOIN_ACK()     => \&join_part,
                PART_ACK()     => \&join_part,
                PUBLIC_MSG()   => \&public_msg,
                PRIVATE_MSG()  => \&private_msg,
                USER_JOINS()   => \&user_joins,
                USER_PARTS()   => \&user_joins,
                CHANNEL_ITEM() => \&list_channel,
                USER_ITEM()    => \&list_user,
               );

# create the UDP socket
my $server      = shift || hostname();
my $port        = shift || 2027;
my $mcast_port  = shift || 2028;
my $socket = IO::Socket::INET->new(PeerHost  => $server,
                                   PeerPort  => $port,
                                   Proto     => 'udp') or die $@;
my $msocket = IO::Socket::Multicast->new(LocalPort => $mcast_port,
                                         Reuse     => 1 ) or die $@;

$nickname = do_login();  # try to log in
die "Can't log in.\n" unless $nickname;

my $select = IO::Select->new($socket,$msocket,\*STDIN);
LOOP:
while (my @ready = $select->can_read) {
  foreach (@ready) {
    if ($_ eq \*STDIN) {
      do_user(\*STDIN) || last LOOP;
    } else {
      do_server($_);
    }
  }
}

# handle a command from the user
sub do_user {
  my $h = shift;
  my $data;
  return   unless sysread($h,$data,1024);  # longest line
  return 1 unless $data =~ /\S+/;
  chomp($data);
  my($command,$args) = $data =~ m!^/(\S+)\s*(.*)!;
  ($command,$args) = ('public',$data) unless $command;
  my $sub = $COMMANDS{lc $command};
  return warn "$command: unknown command\n" unless $sub;
  return $sub->($args);
}

# handle a message from the server
sub do_server {
  my $h = shift;
  my $msg;
  die "recv(): $!" unless my $peer = recv($h,$msg,1024,0);  # longest packet
  my ($mess,$args) = unpack "na*",$msg;
  my $sub = $MESSAGES{$mess} 
            || return warn "$mess: unknown message from server\n";
  $sub->($mess,$args);
  return $mess;
}

sub do_send {
  my ($code,$text) = @_;
  return unless $socket;
  $text ||= '';
  my $msg = pack "na*",$code,$text;
  die "send(): $!" unless send($socket,$msg,0);
}

# Login prompts user for nickname and tries to log in
# repeatedly over a period of 30 s
sub do_login {
  my $nickname = get_nickname();  # read from user
  my $count = 0;
  my $select = IO::Select->new($socket);
  while (++$count <= 5) {
    warn "trying to log in ($count)...\n";
    do_send(LOGIN_REQ,$nickname);
    next unless $select->can_read(6);
    return $nickname if do_server($socket) == LOGIN_ACK;
    $nickname = get_nickname();
  }
  return;
}

sub get_nickname {
  while (1) {
    local $| = 1;
    print "Your nickname: ";
    last unless defined(my $nick = <STDIN>);
    chomp($nick);
    return $nick if $nick =~ /^\S+$/;
    warn "Invalid nickname.  Must contain no spaces.\n";
  }
}

sub error {
  my ($code,$args) = @_;
  print "\t** ERROR: $args **\n";
}

sub login_ack {
  my ($code,$nickname) = @_;
  print "\tLog in successful.  Welcome $nickname.\n";
}

sub join_part {
  my ($code,$msg) = @_;
  my ($title,$users,$mcast_addr) = $msg =~ /^(\S+) (\d+) ([\d.]+)/;
  if ($code == JOIN_ACK) {
    # add multicast address to the list that we receive
    $msocket->mcast_add($mcast_addr);
    print "\tWelcome to the $title Channel ($users users)\n";
  } else {
    $msocket->mcast_drop($mcast_addr);
    print "\tYou have left the $title Channel\n";
  }
}
sub list_channel {
  my ($code,$msg) = @_;
  my ($title,$count,$mcast_addr,$description) = $msg =~ /^(\S+) (\d+) ([\d.]+) (.+)/;
  printf "\t%-20s %-40s %3d users\n","[$title]",$description,$count;
}
sub public_msg {
  my ($code,$msg) = @_;
  my ($channel,$user,$text) = $msg =~ /^(\S+) (\S+) (.*)/;
  print "$user [$channel]: $text\n";
}
sub private_msg {
  my ($code,$msg) = @_;
  my ($user,$text) = $msg =~ /^(\S+) (.*)/;
  print "$user [**private**]: $text\n";
}
sub user_joins {
  my ($code,$msg) = @_;
  my $verb = $code == USER_JOINS ? 'has entered' : 'has left';
  my ($channel,$user) = $msg =~ /^(\S+) (\S+)/;
  print "\t<$user $verb $channel>\n";
}
sub list_user {
  my ($code,$msg) = @_;
  my ($user,$timeon,$channels) = $msg =~ /^(\S+) (\d+) (.+)/;
  my ($hrs,$min,$sec) = format_time($timeon);
  printf "\t%-20s On: %02d:%02d:%02d Channels: %s\n",$user,$hrs,$min,$sec,$channels;
}
sub format_time {
  my $sec = shift;
  my $hours = int( $sec/(60*60) );
  $sec     -= ($hours*60*60);
  my $min   = int( $sec/60 );
  $sec     -= ($min*60);
  return ($hours,$min,$sec);
}

END {
  do_send(LOGOFF,$nickname) if defined $socket;
}

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

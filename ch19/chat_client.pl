#!/usr/bin/perl -w
# file: chat_client.pl
# Figure 19.2: Chat client using UDP

use strict;
use IO::Socket;
use IO::Select;
use ChatObjects::ChatCodes;
use ChatObjects::Comm;

$SIG{INT} = $SIG{TERM} = sub { exit 0 };
my ($nickname,$server);

# dispatch table for commands from the user
my %COMMANDS = (
                channels  => sub { $server->send_event(LIST_CHANNELS)      },
                join      => sub { $server->send_event(JOIN_REQ,shift)     },
                part      => sub { $server->send_event(PART_REQ,shift)     },
                users     => sub { $server->send_event(LIST_USERS)         },
                public    => sub { $server->send_event(SEND_PUBLIC,shift)  },
                private   => sub { $server->send_event(SEND_PRIVATE,shift) },
                login     => sub { $nickname = do_login()      },
                quit      => sub { undef },
               );

# dispatch table for messages from the server
my %MESSAGES = (
                ERROR()        => \&error,
                LOGIN_ACK()    => \&login_ack,
                JOIN_ACK()     => \&join_part,
                PART_ACK()     => \&join_part,
                PUBLIC_MSG()   => \&public_msg,
                PRIVATE_MSG()  => \&private_msg,
                USER_JOINS()   => \&user_join_part,
                USER_PARTS()   => \&user_join_part,
                CHANNEL_ITEM() => \&list_channel,
                USER_ITEM()    => \&list_user,
               );

# Create and initialize the UDP socket
my $servaddr = shift || 'localhost';
my $servport = shift || 2027;
$server = ChatObjects::Comm->new(PeerAddr  => "$servaddr:$servport") or die $@;

# Try to log in
$nickname = do_login();  
die "Can't log in.\n" unless $nickname;

# Read commands from the user and messages from the server
my $select = IO::Select->new($server->socket,\*STDIN);
LOOP:
while (1) {
  my @ready = $select->can_read;
  foreach (@ready) {
    if ($_ eq \*STDIN) {
      do_user(\*STDIN) || last LOOP;
    } else {
      do_server($_);
    }
  }
}

# called to handle a command from the user
sub do_user {
  my $h = shift;
  my $data;
  return   unless sysread($h,$data,1024);  # longest line
  return 1 unless $data =~ /\S+/;
  chomp($data);
  my($command,$args) = $data =~ m!^/(\S+)\s*(.*)!;
  ($command,$args) = ('public',$data) unless $command;
  my $sub = $COMMANDS{lc $command};
  return do_help() unless $sub;
  return $sub->($args);
}

# called to handle a message from the server
sub do_server {
  die "invalid socket" unless my $s = ChatObjects::Comm->sock2server(shift);
  die "can't receive: $!" unless 
    my ($mess,$args) = $s->recv_event;
  my $sub = $MESSAGES{$mess} || return warn "$mess: unknown message from server\n";
  $sub->($mess,$args);
  return $mess;
}

# try to log in (repeatedly)
sub do_login {
  $server->send_event(LOGOFF,$nickname) if $nickname;
  my $nick = get_nickname();  # read from user
  my $select = IO::Select->new($server->socket);

  for (my $count=1; $count <= 5; $count++) {
    warn "trying to log in ($count)...\n";
    $server->send_event(LOGIN_REQ,$nick);
    next unless $select->can_read(6);
    return $nick if do_server($server->socket) == LOGIN_ACK;
    $nick = get_nickname();
  }

}

# prompt user for his nickname
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

# handle an error message from server
sub error {
  my ($code,$args) = @_;
  print "\t** ERROR: $args **\n";
  print "\tType /help for help\n";
}

# handle login acknowledgement from server
sub login_ack {
  my ($code,$nickname) = @_;
  print "\tLog in successful.  Welcome $nickname.\n";
}

# handle channel join/part messages from server
sub join_part {
  my ($code,$msg) = @_;
  my ($title,$users) = $msg =~ /^(\S+) (\d+)/;
  print $code == JOIN_ACK 
    ? "\tWelcome to the $title Channel ($users users)\n"
    : "\tYou have left the $title Channel\n";
}

# handle channel listing messages from server
sub list_channel {
  my ($code,$msg) = @_;
  my ($title,$count,$description) = $msg =~ /^(\S+) (\d+) (.+)/;
  printf "\t%-20s %-40s %3d users\n","[$title]",$description,$count;
}

# handle a public message from server
sub public_msg {
  my ($code,$msg) = @_;
  my ($channel,$user,$text) = $msg =~ /^(\S+) (\S+) (.*)/;
  print "\t$user [$channel]: $text\n";
}

# handle a private message from server
sub private_msg {
  my ($code,$msg) = @_;
  my ($user,$text) = $msg =~ /^(\S+) (.*)/;
  print "\t$user [**private**]: $text\n";
}

# handle user join/part messages from server
sub user_join_part {
  my ($code,$msg) = @_;
  my $verb = $code == USER_JOINS ? 'has entered' : 'has left';
  my ($channel,$user) = $msg =~ /^(\S+) (\S+)/;
  print "\t<$user $verb $channel>\n";
}

# handle user listing messages from server
sub list_user {
  my ($code,$msg) = @_;
  my ($user,$timeon,$channels) = $msg =~ /^(\S+) (\d+) (.+)/;
  my ($hrs,$min,$sec) = format_time($timeon);
  printf "\t%-15s (on %02d:%02d:%02d) Channels: %s\n",$user,$hrs,$min,$sec,$channels;
}

# nicely formatted time (hr, min sec)
sub format_time {
  my $sec = shift;
  my $hours = int( $sec/(60*60) );
  $sec     -= ($hours*60*60);
  my $min   = int( $sec/60 );
  $sec     -= ($min*60);
  return ($hours,$min,$sec);
}

# print help message
sub do_help {
  print <<END;
	Commands:
	  /channels             List chat channels
	  /join <channel>       Join a channel
	  /part <channel>       Depart a channel
	  /users                List users in current channel
	  /public <msg>         Send a public message
	  /private <user> <msg> Send a private message to user
	  /login                Login again
	  /quit                 Quit

	Typing anything that doesn't begin with a "/" is interpreted as a message
	to the current channel.
END
}

END {
  if (defined $server) {
    $server->send_event(LOGOFF,$nickname);
    $server->close;
  }
}

__END__


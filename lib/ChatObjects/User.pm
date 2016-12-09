package ChatObjects::User;
# file: ChatObjects/User.pm
# Figure 19.6: The ChatObjects::User Module

use strict;
use ChatObjects::ChatCodes;
use Socket;

use overload ( '""' => 'nickname',
               fallback => 1 );

# Information on a user
my %NICKNAMES = ();
my %ADDRESSES = ();

sub new {
  my $package = shift;
  my ($address,$nickname,$server) = @_;
  my $self = bless {
                    address  => $address,
                    nickname => $nickname,
                    server   => $server,
                    timeon   => time(),
                    channels => [],
               },$package;
  $server->send_event(LOGIN_ACK,$nickname,$address);
  return $NICKNAMES{$nickname} = $ADDRESSES{key($address)} = $self;
}

sub lookup_byname { 
  shift;  # get rid of package name
  my $nickname = shift;
  return $NICKNAMES{$nickname};
}

sub lookup_byaddr { 
  shift;  # get rid of package name
  my $addr = shift;
  return $ADDRESSES{key($addr)};
}

sub users { values %NICKNAMES }

sub address         { shift->{address}             }
sub nickname        { shift->{nickname}            }
sub channels        { @{shift->{channels}}         }
sub current_channel { shift->{channels}[0]         }
sub timeon          { shift->{timeon}              }

sub send { 
  my $self = shift;
  my ($code,$msg) = @_;
  $self->{server}->send_event($code,$msg,$self->address);
}

sub logout {
  my $self = shift;
  $_->remove($self) foreach $self->channels;
  delete $NICKNAMES{$self->nickname};
  delete $ADDRESSES{key($self->address)};
  warn "logout: ",$self->nickname,"\n" if main::DEBUG();
}

sub join {
  my $self = shift;
  my $title = shift;
  return $self->send(ERROR,"no channel named $title")
    unless my $channel = ChatObjects::Channel->lookup($title);

  # already belongs to channel, so make it current
  if (grep {$channel eq $_} $self->channels) { 
    my @chan = grep { $channel ne $_ } $self->channels;
    $self->{channels} = \@chan;
  } else {
    $channel->add($self);
  }

  unshift @{$self->{channels}},$channel;
  $self->send(JOIN_ACK,$channel->info);
}

sub part {
  my $self = shift;
  my $title = shift;
  my $channel = $title ? ChatObjects::Channel->lookup($title) : $self->current_channel;
  return $self->send(ERROR,"no channel named $title") unless $channel;

  my @chan = grep { $channel ne $_ } $self->channels;
  return if @chan == $self->channels;  # not a member of that channel!
  my $was_current = $channel eq $self->current_channel;

  $self->{channels} = \@chan;
  $channel->remove($self);
  $self->send(PART_ACK,$channel->info);
  if ($was_current && (my $current = $self->current_channel)) {
    $self->send(JOIN_ACK,$current->info);
  }
}

sub send_public {
  my $self = shift;
  my $text = shift;
  if (my $channel = $self->current_channel) {
    $channel->message($self,$text);
  } else {
    $self->send(ERROR,"no current channel");
  }
}

sub send_private {
  my $self = shift;
  my $msg = shift;
  my ($recipient,$text) = $msg =~ /(\S+)\s*(.*)/;
  return $self->send(ERROR,"no nickname given for recipient of private message") 
    unless $recipient;
  if (my $user = $self->lookup_byname($recipient)) {
    $user->send(PRIVATE_MSG,"$self $text");
  } else {
    $self->send(ERROR,"$recipient: not logged in");
  }
}

sub list_users {
  my $self = shift;
  my $channel = $self->current_channel;
  return $self->send(ERROR,"no current channel")  unless $channel;
  foreach ($channel->users) {
    my $timeon   = time() - $_->timeon;
    my @channels = $_->channels;
    $self->send(USER_ITEM,"$_ $timeon @channels");
  }
}

sub list_channels {
  my $self = shift;
  $self->send(CHANNEL_ITEM,$_->info) foreach ChatObjects::Channel->channels;
}

# utility routine
sub key      { CORE::join ':',sockaddr_in($_[0])  }

1;

__END__

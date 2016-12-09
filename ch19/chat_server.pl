#!/usr/bin/perl -w
# file: chat_server.pl
# Figure 19.5: Chat server using UDP

use strict;
use ChatObjects::ChatCodes;
use ChatObjects::Comm;
use ChatObjects::User;
use ChatObjects::Channel;
use constant DEBUG => 0;

# create a bunch of channels
ChatObjects::Channel->new('CurrentEvents',  'Discussion of current events');
ChatObjects::Channel->new('Weather',        'Talk about the weather');
ChatObjects::Channel->new('Gardening',      'For those with the green thumb');
ChatObjects::Channel->new('Hobbies',        'For hobbyists of all types');
ChatObjects::Channel->new('Pets',           'For our furry and feathered friends');

# dispatch table
my %DISPATCH = (
                LOGOFF()        => 'logout',
                JOIN_REQ()      => 'join',
                PART_REQ()      => 'part',
                SEND_PUBLIC()   => 'send_public',
                SEND_PRIVATE()  => 'send_private',
                LIST_CHANNELS() => 'list_channels',
                LIST_USERS()    => 'list_users',
                );

# create the UDP socket
my $port = shift || 2027;
my $server = ChatObjects::Comm->new(LocalPort=>$port);
warn "servicing incoming requests...\n";

while (1) {
  next unless my ($code,$msg,$addr) = $server->recv_event;

  warn "$code $msg\n" if DEBUG;
  do_login($addr,$msg,$server) && next if $code == LOGIN_REQ;

  my $user = ChatObjects::User->lookup_byaddr($addr);
  $server->send_event(ERROR,"please log in",$addr) && next 
    unless defined $user;

  $server->send_event(ERROR,"unimplemented event code",$addr) && next 
    unless my $dispatch = $DISPATCH{$code};
  $user->$dispatch($msg);
}

sub do_login {
  my ($addr,$nickname,$server) = @_;
  return $server->send_event(ERROR,"nickname already in use",$addr) 
    if ChatObjects::User->lookup_byname($nickname);
  return unless ChatObjects::User->new($addr,$nickname,$server);
}

__END__


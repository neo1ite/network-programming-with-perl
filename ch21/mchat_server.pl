#!/usr/bin/perl -w
# file: mchat_server.pl
# Figure 21.7: Chat server using multicast

use strict;
use IO::Socket::Multicast;
use ChatObjects::ChatCodes;
use ChatObjects::MChannel;
use ChatObjects::MComm;
use constant DEBUG => 0;

# dispatch table
my %dispatch = (
                LOGOFF()        => 'logout',
                JOIN_REQ()      => 'join',
                PART_REQ()      => 'part',
                SEND_PUBLIC()   => 'send_public',
                SEND_PRIVATE()  => 'send_private',
                LIST_CHANNELS() => 'list_channels',
                LIST_USERS()    => 'list_users',
                );

# create the UDP socket
my $port       = shift || 2027;
my $mcast_port = shift || 2028;
my $server = ChatObjects::MComm->new($port,$mcast_port);

# create a bunch of channels
#                title              description                  mcast addr
my $mc = 'ChatObjects::MChannel';
$mc->new('CurrentEvents','Discussion of current events',       '225.1.0.1',$server);
$mc->new('Weather',      'Talk about the weather',             '225.1.0.2',$server);
$mc->new('Gardening',    'For those with the green thumb',     '225.1.0.3',$server);
$mc->new('Hobbies',      'For hobbiests of all types',         '225.1.0.4',$server);
$mc->new('Pets',         'For our furry and feathered friends','225.1.0.5',$server);

warn "servicing incoming requests...\n";

while (1) {
  my $data;
  next unless my ($code,$msg,$addr) = $server->recv_event;

  warn "$code $msg\n" if DEBUG;
  do_login($addr,$msg,$server) && next if $code == LOGIN_REQ;

  my $user = ChatObjects::User->lookup_byaddr($addr);
  $server->send_event(ERROR,"please log in",$addr) && next 
    unless defined $user;

  $server->send_event(ERROR,"unimplemented message code",$addr) && next 
    unless my $dispatch = $dispatch{$code};
  $user->$dispatch($msg);
}

sub do_login {
  my ($addr,$nickname,$server) = @_;
  return $server->send_event(ERROR,"nickname already in use",$addr) 
    if ChatObjects::User->lookup_byname($nickname);
  return unless ChatObjects::User->new($addr,$nickname,$server);
}

__END__

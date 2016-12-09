package ChatObjects::MComm;
# file: ChatObjects/MComm.pm
# Figure 21.8: ChatObjects::MComm Module

use strict;
use ChatObjects::Comm;
use IO::Socket::Multicast;
use vars '@ISA';
@ISA = 'ChatObjects::Comm';

sub new {
  my $pack = shift;
  my ($port,$mport) = @_;
  my $self = $pack->SUPER::new(LocalPort=>$port);
  $self->{mport} = $mport;
  $self->socket->mcast_ttl(64);
  warn "setting ttl to ",$self->socket->mcast_ttl;
  return $self;
}

sub create_socket { shift; IO::Socket::Multicast->new(@_) }

sub mport { shift->{mport} }

sub mcast_event {
  my $self = shift;
  my ($code,$text,$mcast_addr) = @_;
  my $dest = sockaddr_in($self->mport,inet_aton($mcast_addr));
  $self->send_event($code,$text,$dest);
}

1;

__END__


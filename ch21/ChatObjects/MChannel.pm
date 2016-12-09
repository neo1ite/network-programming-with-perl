package ChatObjects::MChannel;
# file ChatObjects/MChannel.pm
# Figure 21.9: ChatObjects::MChannel Module

use Socket;
use ChatObjects::Channel;
use ChatObjects::ChatCodes;
use vars '@ISA';
@ISA = 'ChatObjects::Channel';

sub new {
  my $pack  = shift;
  my ($title,$description,$mcast_addr,$server) = @_;
  my $self = $pack->SUPER::new($title,$description);
  @{$self}{'mcast_addr','server'} = ($mcast_addr,$server);
  return bless $self,$pack;
}
sub mcast_addr  { shift->{mcast_addr} }
sub server      { shift->{server} }
sub info  {
  my $self = shift;
  my $user_count = $self->users;
  return "$self $user_count $self->{mcast_addr} $self->{description}";
}

sub mcast_dest {
  my $self = shift;
  my $mport  = $self->server->mport;
  my $group = $self->mcast_addr;
  return scalar sockaddr_in($mport,inet_aton($group));
}

sub send_to_all {
  my $self = shift;
  my ($code,$text) = @_;
  my $dest = $self->mcast_dest;
  my $server = $self->server;
  $server->send_event($code,$text,$dest) || warn $!;
}

1;

__END__

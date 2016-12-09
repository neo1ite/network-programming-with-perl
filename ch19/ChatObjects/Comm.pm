package ChatObjects::Comm;
# file: ChatObjects/Comm.pm
# Figure 19.3: The ChatObjects::Comm Module

use strict;
use Carp 'croak';
use IO::Socket;

my %SERVERS;

sub new {
  my $pack = shift;
  my $sock = $pack->create_socket(@_) or croak($@);
  return $SERVERS{$sock} = bless {sock=>$sock},$pack;
}
sub create_socket { shift; IO::Socket::INET->new(@_,Proto=>'udp') }
sub sock2server { shift;  return $SERVERS{$_[0]} }
sub socket      { shift->{sock}  }
sub close {
  my $self = shift;
  delete $SERVERS{$self->socket};
  close $self->socket;
}
sub send_event {
  my $self = shift;
  my ($code,$text,$address) = @_;
  $text ||= '';
  my $msg = pack "na*",$code,$text;
  if (defined $address) {
    send($self->socket,$msg,0,$address);
  }  else {
    send($self->socket,$msg,0);
  }
}
sub recv_event {
  my $self = shift;
  my $data;
  return unless my $addr = recv($self->socket,$data,1024,0);
  my ($code,$text) = unpack("na*",$data);
  return ($code,$text,$addr);
}

1;

__END__

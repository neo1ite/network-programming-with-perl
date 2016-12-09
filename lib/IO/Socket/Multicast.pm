package IO::Socket::Multicast;
# file: IO/Socket/Multicast.pm
# Figure 21.3: The IO::Socket::Multicast module provides multicasting services for sockets

# NOTE: If you have a C compiler, you are better off using the IO::Socket::Multicast
# module on CPAN, which is easier to install than getting h2ph to work.

use strict;
use Carp 'croak';
use IO::Interface 'IFF_MULTICAST';
use vars qw($VERSION @ISA);

@ISA = qw(IO::Socket::INET);
$VERSION = '1.00';

# order of import is important in order to avoid redefinition warnings
require IO::Socket;
IO::Socket->import('inet_aton','inet_ntoa');
require "netinet/in.ph";
my $IP_LEVEL = getprotobyname('ip') || 0;  

sub new {
  my $class = shift;
  unshift @_,(Proto => 'udp') unless @_;
  $class->SUPER::new(@_);
}

sub configure {
  my($self,$arg) = @_;
  $arg->{Proto} ||= 'udp';
  $self->SUPER::configure($arg);
}

sub mcast_add {  
  my $sock = shift;
  my $mcast_addr = shift || croak 'usage: $sock->mcast_add($mcast_addr [,$interface])';
  my $local_addr = get_if_addr($sock,shift);
  my $ip_mreq = inet_aton($mcast_addr).inet_aton($local_addr);
  setsockopt($sock,$IP_LEVEL,IP_ADD_MEMBERSHIP(),$ip_mreq);
}

sub mcast_drop {  
  my $sock = shift;
  my $mcast_addr = shift || croak 'usage: $sock->mcast_drop($mcast_addr [,$interface])';
  my $local_addr = get_if_addr($sock,shift);
  my $ip_mreq = inet_aton($mcast_addr).inet_aton($local_addr);
  setsockopt($sock,$IP_LEVEL,IP_DROP_MEMBERSHIP(),$ip_mreq);
}

sub mcast_if {
  my $sock = shift;
  if (@_) { # set the outgoing interface
    my $addr = get_if_addr($sock,shift);
    return setsockopt($sock,$IP_LEVEL,IP_MULTICAST_IF(),inet_aton($addr));
  } else { # get the outgoing interface
    return unless my $result = getsockopt($sock,$IP_LEVEL,IP_MULTICAST_IF());
    $result = substr($result,4,4) if length $result > 4;
    return find_interface($sock,inet_ntoa($result));
  }
}

sub mcast_loopback {
  my $sock   = shift;
  if (@_) { # set the loopback flag
    my $enable = shift;
    return setsockopt($sock,$IP_LEVEL,IP_MULTICAST_LOOP(),$enable ? 1 : 0);
  } else {
    return unpack 'I',getsockopt($sock,$IP_LEVEL,IP_MULTICAST_LOOP() );
  }
}

sub mcast_ttl {
  my $sock   = shift;
  if (@_) { # set the ttl
    my $hops   = shift;
    return setsockopt($sock,$IP_LEVEL,IP_MULTICAST_TTL(),pack 'I',$hops);
  } else {
    return unpack 'I',getsockopt($sock,$IP_LEVEL,IP_MULTICAST_TTL() );
  }
}

sub get_if_addr {
  my ($sock,$interface) = @_;
  return '0.0.0.0' unless $interface;
  return $interface if $interface =~ /^\d+\.\d+\.\d+\.\d+$/;
  croak "unknown or unconfigured interace $interface" 
    unless my $addr = $sock->if_addr($interface);
  croak "interface is not multicast capable"
    unless $sock->if_flags($interface) & IFF_MULTICAST;
  return $addr;

}

sub find_interface {
  my ($sock,$addr) = @_;
  foreach ($sock->if_list) {
    return $_ if $sock->if_addr($_) eq $addr;
  }
  return;  # couldn't find it
}

1;

__END__

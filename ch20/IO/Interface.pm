package IO::Interface;
# file: IO/Interface.pm;
# Figure 20.3: IO::Interface module

# NOTE: If you have a C compiler you're better off using the CPAN
# IO::Interface module -- it will be more portable than using the h2ph tool.

use strict;
use Carp 'croak';
use Config;

use vars qw(@EXPORT @EXPORT_OK @ISA %EXPORT_TAGS $VERSION %sizeof);
require Exporter;

my @functions = qw(if_addr   if_broadcast if_netmask if_dstaddr 
                   if_hwaddr if_flags     if_list);
my @flags     = qw(IFF_ALLMULTI    IFF_AUTOMEDIA  IFF_BROADCAST
                   IFF_DEBUG       IFF_LOOPBACK   IFF_MASTER
                   IFF_MULTICAST   IFF_NOARP      IFF_NOTRAILERS
                   IFF_POINTOPOINT IFF_PORTSEL    IFF_PROMISC
                   IFF_RUNNING     IFF_SLAVE      IFF_UP);

%EXPORT_TAGS = ( 'all'        => [@functions,@flags],
                 'functions'  => \@functions,
                 'flags'      => \@flags,
               );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
@ISA = qw(Exporter);
$VERSION = '0.01';

require Socket;
Socket->import('inet_ntoa');

require "net/if.ph";
require "sys/ioctl.ph";
require "sys/sockio.ph" unless defined &SIOCGIFCONF;
%sizeof = ('struct ifconf' => 2 * $Config{ptrsize},
           'struct ifreq'  => 2 * IFNAMSIZ());

my $IFNAMSIZ    = IFNAMSIZ();
my $IFHWADDRLEN = defined &IFHWADDRLEN ? IFHWADDRLEN() : 6;
sub IFREQ_NAME  { "Z$IFNAMSIZ x$IFNAMSIZ" } # name
sub IFREQ_ADDR  { "Z$IFNAMSIZ s x2 a4"    } # retrieve IP addresses
sub IFREQ_ETHER { "Z$IFNAMSIZ s C$IFHWADDRLEN" }  # retrieve ethernet addr
sub IFREQ_FLAG  { "Z$IFNAMSIZ s"          }       # retrieve flags

{ 
  no strict 'refs';
  *{"IO\:\:Socket\:\:$_"} = \&$_ foreach @functions;
}

sub if_addr {
  my ($sock,$ifname) = @_;
  my $ifreq  = pack(IFREQ_NAME,$ifname);
  return unless ioctl($sock,SIOCGIFADDR(),$ifreq);
  my ($name,$family,$addr) = unpack(IFREQ_ADDR,$ifreq);
  return inet_ntoa($addr);
}

sub if_broadcast {
  my ($sock,$ifname) = @_;
  my $ifreq  = pack(IFREQ_NAME,$ifname);
  return unless ioctl($sock,SIOCGIFBRDADDR(),$ifreq);
  my($name,$protocol,$addr) = unpack(IFREQ_ADDR,$ifreq);
  return if $addr eq "\0\0\0\0";
  return inet_ntoa($addr);
}

sub if_netmask {
  my ($sock,$ifname) = @_;
  my $ifreq  = pack(IFREQ_NAME,$ifname);
  return unless ioctl($sock,SIOCGIFNETMASK(),$ifreq);
  my($name,$protocol,$addr) = unpack(IFREQ_ADDR,$ifreq);
  return inet_ntoa($addr);
}

sub if_dstaddr {
  my ($sock,$ifname) = @_;
  my $ifreq  = pack(IFREQ_NAME,$ifname);
  return unless ioctl($sock,SIOCGIFDSTADDR(),$ifreq);
  my($name,$protocol,$addr) = unpack(IFREQ_ADDR,$ifreq);
  return if $addr eq "\0\0\0\0";
  return inet_ntoa($addr);
}

sub if_hwaddr {
  my ($sock,$ifname) = @_;
  return unless defined &SIOCGIFHWADDR;
  my $ifreq  = pack(IFREQ_NAME,$ifname);
  return unless ioctl($sock,SIOCGIFHWADDR(),$ifreq);
  my($name,$proto,@addr) = unpack(IFREQ_ETHER,$ifreq);
  return unless grep { $_ != 0 } @addr;
  return join ':',map {sprintf "%02x",$_} @addr;
}

sub if_flags {
  my ($sock,$ifname) = @_;
  my $ifreq  = pack(IFREQ_NAME,$ifname);
  return unless ioctl($sock,SIOCGIFFLAGS(),$ifreq);
  my($name,$flags) = unpack(IFREQ_FLAG,$ifreq);
  return $flags;
}

sub if_list {
  my $sock = shift;
  my $ifreq_length = $sizeof{'struct ifreq'};
  my $buffer = "\0"x($ifreq_length*20);  # allow as many as 20 interfaces
  my $format = $Config{ptrsize} == 8 ? "ix4p" : "ip";
  my $ifclist = pack $format,length $buffer,$buffer;
  return unless ioctl($sock,SIOCGIFCONF(),$ifclist);
  my %interfaces;
  my $ifclen = unpack "i",$ifclist;
  for (my $start=0;$start < $ifclen;$start+=$ifreq_length) {
    my $ifreq = substr($buffer,$start,$ifreq_length);
    my $ifname = unpack(IFREQ_NAME,$ifreq);
    $interfaces{$ifname} = undef;
  }
  return sort keys %interfaces;
}

1;

__END__

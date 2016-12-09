package Sockatmark;
# file: Sockatmark.pm
# Figure 17.5: The Sockatmark.pm module provides the IO::Socket->atmark() method
use strict;
use vars qw(@ISA @EXPORT_OK);

require Exporter;
@ISA = 'Exporter';
@EXPORT_OK = 'sockatmark';

$^O eq 'Win32'      && eval "sub SIOCATMARK { 0x40047307 }";
defined &SIOCATMARK || eval { require "sys/socket.ph"  };
defined &SIOCATMARK || eval { require "sys/ioctl.ph"   };
defined &SIOCATMARK || eval { require "sys/sockio.ph"  };
defined &SIOCATMARK || eval { require "sys/sockios.ph" };
defined &SIOCATMARK or die "Couldn't find SIOCATMARK";

sub sockatmark {
  my $sock = shift;
  my $d;
  return unless ioctl($sock,SIOCATMARK(),$d);
  return unpack("i",$d) != 0;
}

sub IO::Socket::atmark {  return sockatmark($_[0]) }

1;

package Net::NetmaskLite;
# file: Net/NetmaskLite.pm;
# Chapter 3/Appendix A: This module illustrates the numeric relationship between the
# host address, the network address, the broadcast address and the netmask.

use strict;
use Carp 'croak';
use overload '""'=>netmask;

sub new {
  my $pack = shift;
  my $mask = shift or croak "Usage: Netmask->new(\$dotted_IP_addr)\n";
  my $num = ($mask =~ /^\d+$/ && $mask <= 32) 
            ? _tomask($mask)
            : _tonum($mask);
  bless \$num,$pack;
}

sub hostpart {
  my $mask = shift;
  my $addr = tonum(shift) or croak "Usage: \$netmask->hostpart(\$dotted_IP_addr)\n";
  _toaddr($addr & ~$$mask);
}

sub netpart{
  my $mask = shift;
  my $addr = tonum(shift) or croak "Usage: \$netmask->hostpart(\$dotted_IP_addr)\n";
  _toaddr($addr & $$mask);
}

sub broadcast {
  my $mask = shift;
  my $addr = tonum(shift) or croak "Usage: \$netmask->hostpart(\$dotted_IP_addr)\n";
  _toaddr($addr | ($$mask ^ 0xffffffff));
}

sub network {
  my $mask = shift;
  my $addr = tonum(shift) or croak "Usage: \$netmask->hostpart(\$dotted_IP_addr)\n";
  _toaddr($addr & ($$mask & 0xffffffff));
}

sub netmask {  _toaddr(${shift()}); }

# utilities
sub _tomask { 
  my $ones   = shift;
  unpack "L",pack "b*",('1' x $ones) . ('0' x (32-$ones));
}
sub _tonum  { unpack "L",pack("C4",split /\./,shift) }
sub _toaddr { join '.',unpack("C4",pack("L",shift))   }

1;

__END__

=head1 NAME

Net::NetmaskLite - IP address netmask utility

=head1 SYNOPSIS

  use Net::NetmaskLite;

  $mask = Net::NetmaskLite->new('255.255.255.248');
  $broadcast = $mask->broadcast('64.7.3.42');
  $network   = $mask->network('64.7.3.42');

  $hostpart  =  $mask->hostpart('64.7.3.42');
  $netpart   =  $mask->netpart('64.7.3.42');

=head1 DESCRIPTION

This package provides an object which can be used for deriving the
broadcast and network addresses given an Internet netmask.

=head1 CONSTRUCTOR

=over 4

=item $mask = Net::NetmaskLite->new($mask)

The new() constructor creates a new netmask.  C<$mask> is the desired
mask.  You may use either dotted decimal form (255.255.255.0) or
bitcount form (24) for the mask.

The constructor returns a Net::NetmaskLite object, which can be used for
further manipulation.

=back

=head1 METHODS

=over 4

=item $bcast = $mask->broadcast($addr)

Given an IP address in dotted decimal form, the broadcast() method
returns the proper broadcast address, also in dotted decimal form.

=item $network = $mask->network($addr)

Given an IP address in dotted decimal form, the network() method
returns the proper network address in dotted decimal form.

=item $addr = $mask->hostpart($addr)

Given an IP address in dotted decimal form, the hostpart() method
returns the host part of the address in dotted decimal form.

=item $addr = $mask->netpart($addr)

Given an IP address in dotted decimal form, the hostpart() method
returns the network part of the address in dotted decimal form.

=item $addr = $mask->netmask

This just returns the original netmask in dotted decimal form.  The
quote operator is overloaded to call netmask() when the object is used
in a string context.

=back

=head2 Example:

Given a netmask of 255.255.255.248 and an IP address of 64.7.3.42, the
following values are returned:

 netmask:    255.255.255.248
 broadcast:  64.7.3.47
 network:    64.7.3.40
 hostpart:   0.0.0.2
 netpart:    64.7.3.40

=head1 SEE ALSO

L<Socket>
L<perl>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>

=head1 COPYRIGHT

Copyright (c) 2000 Lincoln Stein. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

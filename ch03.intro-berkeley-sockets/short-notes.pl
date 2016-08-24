#!/usr/bin/perl
use strict;
use feature 'say';

# protocols ID'd by short int
# lookup socket protocol num by name
my $protocol = 'tcp'; # some protocol
my $protonum = getprotobyname($protocol);

=head1 3 things needed for socket connection
 1) domain: INET or UNIX (usually)
 2) type: STREAM, DGRAM, or RAW (SOCK_*)
 3) protocol: lots: tcp, udp, icmp, raw, etc.
=cut

=head2 Socket addressing
 UNIX domain: address == file path
 INET domain: address == 3 parts
  1) IP address
  2) port
  3) protocol
=cut

=head2 IP Address
32-bit number used to ID a network interface on host machine
usually spelled out as 4 dot-separated octets ("dotted quad address")
143.48.7.1 == 0x8f3071
=cut

# sockaddr_in struct
# packed binary structure called sockaddr_in: host address & port
my $packed_address = inet_aton($dotted_quad);
# and the opposite
$dotted_quad = inet_ntoa($packed_address):
my $packed_addres

# socket address with port
$socket_addr = sockaddr_in($port, $address);
($port,$address) = sockaddr_in($socket_addr);

# gethostbyname function
($name,$aliases,$type,$len,$packed_addr) = gethostbyname($name);
=head2
=item name - cannonical hostname (official name)
=item aliases
=item type
=item len
=item packed_addr
=cut

# gethostbyaddr function
# this is a reverse lookup
($name,$aliases,$type,$len,$packed_addr) = gethostbyaddr($packed_addr,$family);
=head2
=item name - canonical hostname
=item aliases
=item type
=item len
=item packed_addr
=cut

# get protocol # by human-readable name
$number = getprotobyname($protocol);
($name, $aliases, $number) = getprotobyname($protocol);

# lookup protocol name by its #
$name = getprotobynumber($protocol_number);
($name,$aliases,$number) = getprotobynumber($protocol_number);

# lookup port number by type of service
$port = getservbyname($service,$protocol);
($name,$aliases,$port,$protocol) = getservbyname($service,$protocol);

# lookup service name by its port #
$port = getservbyport($port,$protocol);
($name,$aliases,$port,$protocol) = getservbyport($port,$protocol);


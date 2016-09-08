# IO::Socket methods
use IO::Socket;

# print - method or function
$sock->print('here is data');
print $sock 'here is also data');

# uber flexible socket creation with options
# host or IP
$sock = IO::Socket::INET->new('wuarchive.wustl.edu:echo'); # service name
$sock = IO::Socket::INET->new('wuarchive.wustl.edu:7'); # service port
$sock = IO::Socket::INET->new('128.252.120.8:echo'); # service port
$sock = IO::Socket::INET->new('128.252.120.8:7'); # service port

# named argument-style constructor
$echo = IO::Socket::INET->new(PeerAddr => 'wuarchive.wustl.edu',
                              PeerPort => 'echo(7)',
                              Type => SOCK_STREAM,
                              Proto => 'tcp')
                        or die "Can't connect: $!\n";

=head IO::Socket::INET argument names
=item PeerAddr
=item PeerHost
=item PeerPort
=item LocalAddr
=item LocalHost
=item LocalPort
=item Proto
=item Type
=item Listen
=item Reuse
=item Timeout
=item MultiHomed
=cut

# IO::Socket Object Methods


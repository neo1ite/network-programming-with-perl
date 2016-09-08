# request socket ip address/port binding from OS
$boolean = bind(SOCK, $my_addr);

# notify operating system that socket is used to accept incoming connections
$boolean = listen(SOCK, $max_queue);

# accept a connection from a client
$remote_addr = accept(CONNECTED_SOCKET, LISTEN_SOCKET);

# get info about a socket
# packed address of local socket
$my_addr = getsockname(SOCK);
# packed address of remote socket
$remote_address = getpeername(SOCK);
# as usual, unpack these with sockaddr_in
($port, $ip) = sockaddr_in($remote_addr);
$host = gethostbyaddr($ip, AF_INET);

# socket options
$value = getsockopt(SOCK, $level, $option_name);
$boolean = setsockopt(SOCK, $level, $option_name, $option_value);

# e.g.
setsockopt(SOCK,SO_SOCKET,SO_BROADCAST,1);
=head1 common socket options
=item SO_REUSEADDR
=item SO_KEEPALIVE
=item SO_LINGER
=item SO_BROADCAST
=item SO_OOBINLINE
=item SO_SNDLOWAT
=item SO_RECVLOWAT
=item SO_TYPE
=item SO_ERROR
=cut

# send data with configuration flags
# often used for sending urgent packets or broadcasting
$bytes = send(SOCK,$data,$flogs [,$destination]);

# receive data with configuration and buffering options
$address = recv(SOCK,$buffer,$length,$flags);

# creates two unnamed sockets connected end to end
$boolean = socketpair(SOCK_A,SOCK_B,$domain,$type,$protocol);
# most systems support UNIX-domain only
$boolean = socketpair(SOCK_A,SOCK_B,AF_UNIX,SOCK_STREAM,PF_UNSPEC) or die $!;

# socket variables for setting end-of-line sequence
use Socket qw(:DEFAULT :crlf);
say join q{,} => map encode_qp($_), $CR, $LF, $CRLF;

=head Connection errors (connect() function)
=item ECONNREFUSED remote host up, but no server listening
=item ETIMEDOUT remote host down, but try to connect
=item ENETUNREACH network misconfigured, so network is unreachable
=item ENOTSOCK a programmer tries connect() on a filehandle
=item EISCONN a programmer tries connect() when a connection is already open
=cut

=head read/write errors (read(), sysread(), write(), syswrite(), print() functions)
=item EOF server crashes while reading (identical to closed connection)
=item EPIPE server crashes while writing
=item server crashes while establishing connection - block indefinitely until reconnected, then send back a reject message; can avoid with SO_KEEPALIVE
=item network goes down while connection established; when restored, IO operation has blocked until net available
=item 
=cut

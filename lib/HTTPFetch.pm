package HTTPFetch;
# file: HTTPFetch.pm
# Figure 13.10: The HTTPFetch module uses nonblocking connects 
# to retrieve several web pages in parallel

use strict;
use IO::Socket qw(:DEFAULT :crlf);
use File::Path;
use File::Basename;
use IO::File;
use Errno 'EINPROGRESS';

sub new {
  my $pack = shift;
  my $url = shift;

  # parse URL, return components
  my ($host,$port,$path) = $pack->parse_url($url);
  return $pack->error("invalid url: $url\n") unless $host;

  # connect to remote host in nonblocking way
  my $sock = $pack->connect($host,$port);
  return $pack->error("can't connect: $!") unless $sock;

  # create a name for the local file to copy data into
  my $localpath = "./$host/$path";
  $localpath .= "index.html" if $localpath =~ m!/$!;

  return bless {
                # ("waiting", "reading header" or "reading body")
                status     => 'waiting',  
                socket     => $sock,
                remotepath => $path,
                localpath  => $localpath,
                url        => $url,
                localfh    => undef,  # not opened yet
                header     => undef,  # none yet
               },$pack;
}

# this will return the socket associated with the object
sub socket { shift->{socket} }

# very basic URL-parsing sub
sub parse_url {
  my $self = shift;
  my $url = shift;
  my ($hostent,$path) = $url =~ m!^http://([^/]+)(/?[^\#]*)! or return;
  $path ||= '/';
  my ($host,$port) = split(':',$hostent);
  return ($host,$port||80,$path);
}

# this is called to connect to remote host
sub connect {
  my $pack = shift;
  my ($host,$port) = @_;

  my $sock = IO::Socket::INET->new(Proto => 'tcp',
                                   Type  => SOCK_STREAM);
  return unless $sock;
  $sock->blocking(0);
  my $addr = sockaddr_in($port,inet_aton($host));
  my $result = $sock->connect($addr);
  return $sock if $result;  # return the socket if connected immediately
  return $sock if $! == EINPROGRESS;  # or if it's in progress
  return;                             # return undef on other errors
}

# this is called to send the HTTP request
sub send_request {
  my $self = shift;
  die "not in right state" unless $self->{status} eq 'waiting';
  unless ($self->{socket}->connected) {
    $! = $self->{socket}->sockopt(SO_ERROR);
    return $self->error("couldn't connect: $!") ;
  }
  $self->{socket}->blocking(1);  # back to normal blocking mode
  return $self->error("syswrite(): $!") 
    unless syswrite($self->{socket},"GET $self->{remotepath} HTTP/1.0$CRLF$CRLF");
  $self->{status} = 'reading header';
}

# this is called when the socket is ready to be read
sub read {
  my $self = shift;
  return $self->read_header if $self->{status} eq 'reading header';
  return $self->read_body   if $self->{status} eq 'reading body';
}

# read the header through to the $CRLF$CRLF (blank line)
# return a true value for 200 OK
sub read_header {
  my $self = shift;

  my $bytes = sysread($self->{socket},$self->{header},1024,length $self->{header});
  return $self->error("Unexpected close before header read") unless $bytes > 0;

  # have we found the CRLF yet?
  my $i = rindex($self->{header},"$CRLF$CRLF");
  return 1 unless $i >= 0;  # no, so keep waiting

  # found the header
  my ($stat_code,$stat_msg) = $self->{header} =~ m!^HTTP/1\.[01] (\d+) (.+)$CRLF!o;

  # On non-200 status codes return an error
  return $self->error("$stat_code $stat_msg") unless $stat_code == 200;

  # If we have stuff after the header, then write it out to local file
  my $extra_data = substr($self->{header},$i+4);
  $self->write_local($extra_data) if length $extra_data;

  undef $self->{header};  # don't need header now
  return $self->{status} = 'reading body';
}

# this is called to read the body of the message and write it to our local file
sub read_body {
  my $self = shift;
  my $data;
  return $self->write_local($data) if sysread($self->{socket},$data,1024);
  return;
}

# this is called to write some data to the local file
sub write_local {
  my $self = shift;
  my $data = shift;
  unless ($self->{localfh}) {
    mkpath(dirname($self->{localpath}));
    $self->{localfh} = IO::File->new($self->{localpath},">")
      ||  return $self->error("Can't open local file: $!");
  }
  syswrite($self->{localfh},$data) || return $self->error("Can't write local file: $!");
}

# warn in case of error and return undef
sub error { 
  my ($self,@msg) = @_;
  unshift @msg,"$self->{url}: " if ref $self;
  warn @msg,"\n";
  return;
}

1;

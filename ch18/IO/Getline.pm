package IO::Getline;
# file: IO/Getline.pm

# Figure 13.2: The IO::Getline module
# line-oriented reading from sockets/handles with access to
# internal buffer.

use strict;
use Carp 'croak';
use IO::Handle;
use Errno 'EWOULDBLOCK';
use constant READSIZE => 1024;
use vars '$AUTOLOAD';

sub new {
  my $pack = shift;
  my $handle = shift || croak "usage: Readline->new(\$handle)\n";
  my $buffer = '';
  $handle->blocking(0);
  my $self = { handle => $handle,
               buffer => $buffer,
               index  => 0,
               eof    => 0,
               error  => 0,
             };
  return bless $self,$pack;
}

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self) or croak "$self is not an object";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion
  eval { $self->{handle}->$name(@_) };
  croak $@ if $@;
}

sub handle { $_[0]->{handle} }

sub error {  $_[0]->{error} }

sub flush {
  my $self = shift;
  $self->{buffer} = '';
  $self->{index} = 0;
}

# $bytes = $reader->getline($data);
# returns bytes read on success
# returns undef on error
# returns 0 on EOF
# returns 0E0 if would block
sub getline {
  my $self    = shift;

  return 0 if $self->{eof};   # a previous read returned EOF
  return   if $self->{error}; # a previous read returned error

  # Look up position of the line end character in the buffer.
  my $i = index($self->{buffer},$/,$self->{index});
  if ($i < 0) {
    $self->{index} = length $self->{buffer};
    my $rc = sysread($self->{handle},
                     $self->{buffer},
                     READSIZE,length $self->{buffer});

    unless (defined $rc) {  # we got an error
      return '0E0' if $! == EWOULDBLOCK;  # wouldblock is OK
      $_[0] = $self->{buffer};            # return whatever we have left
      $self->{error} = $!;                # remember what happened
      return length $_[0];                # and return the size
    } 

    elsif ($rc == 0) {    # we got EOF
      $_[0] = $self->{buffer};            # return whatever we have left
      $self->{eof}++;                     # remember what happened
      return length $_[0];
    }

    # if we get here, we got a positive read, so look for EOL again
    $i = index($self->{buffer},$/,$self->{index});
  }

  # If $i<0, then newline not found.  Pretend this is an EWOULDBLOCK
  if ($i < 0) {
    $self->{index} = length $self->{buffer};
    return '0E0';
  }

  $_[0] = substr($self->{buffer},0,$i+length($/));  # save the line
  substr($self->{buffer},0,$i+length($/)) = '';     # and chop off the rest
  $self->{index} = 0;
  return length $_[0];
}

1;

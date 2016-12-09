package IO::LineBufferedSessionData;
# file: IO/LineBufferedSessionData.pm
# Chapter 13/Appendix A: IO::LineBufferedSessionData Module

use strict;
use Carp;
use IO::SessionData;
use Errno 'EWOULDBLOCK';
use IO::SessionData;
use IO::LineBufferedSet;
use vars '@ISA','$VERSION';

@ISA = 'IO::SessionData';
$VERSION = 1.00;

use constant BUFSIZE => 3000;

# override new() by adding new instance variables
sub new {
  my $pack = shift;
  my $self = $pack->SUPER::new(@_);
  @{$self}{qw(read_limit inbuffer linemode index eof error)} = (BUFSIZE,'',0,0,0,0);
  return $self;
}

# line_mode is set to true if the package detects that you are doing
# line-oriented input.  You can also set this yourself.
sub line_mode        { 
  my $self = shift;
  return defined $_[0] ? $self->{linemode} = $_[0] 
                       : $self->{linemode};
}

# Object method: read_limit([$bufsize])
# Get or set the limit on the size of the read buffer.
# Only affects line-oriented reading.
sub read_limit { 
  my $self = shift;
  return defined $_[0] ? $self->{read_limit} = $_[0] 
                       : $self->{read_limit};
}

# Add three new methods to tell us when there's buffered data available.
sub buffered        { return length shift->{inbuffer} }
sub lines_pending   { 
  my $self = shift;
  return index($self->{inbuffer},$/,$self->{index}) >= 0;
}
sub has_buffered_data {
  my $self = shift;
  return $self->line_mode ? $self->lines_pending : $self->buffered;
}

# override read() to deal with buffered data
sub read {
  my $self = shift;

  $self->line_mode(0);            # turn off line mode
  $self->{index} = 0;             # rezero our internal newline pointer
  if ($self->buffered) { # buffered data from an earlier getline
    my $data = substr($self->{inbuffer},0,$_[1]);
    substr($_[0], $_[2]||0, $_[1]) = $data;
    substr($self->{inbuffer},0,$_[1]) = '';
    return length $data;
  }

  # if we get here, do the inherited read
  return $self->SUPER::read(@_);
}

# return the last error
sub error { $_[0]->{error} }

# $bytes = $reader->getline($data);
# returns bytes read on success
# returns undef on error
# returns 0 on EOF
# returns 0E0 if would block
sub getline {
  my $self = shift;
  croak "usage: getline(\$scalar)\n" unless @_ == 1;

  $self->line_mode(1);  # turn on line mode
  return unless my $handle = $self->handle;

  undef $_[0];  # empty the caller's scalar

  # If inbuffer is gone, then we encountered a read error and returned
  # everything we had on a previous pass.  So return undef.
  return 0 if $self->{eof};
  return   if $self->{error};

  # Look up position of the line end character in the buffer.
  my $i = index($self->{inbuffer},$/,$self->{index});

  # If the line end character is not there and the buffer is below the
  # read length, then fetch some more data.
  if ($i < 0 and $self->buffered < $self->read_limit) {
    $self->{index} = $self->buffered;
    my $rc = $self->SUPER::read($self->{inbuffer},BUFSIZE,$self->buffered);

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

    # try once again to find the newline
    $i = index($self->{inbuffer},$/,$self->{index});
  }

  # If $i < 0, then newline not found.  If we've already buffered more
  # than the limit, then return everything up to the limit
  if ($i < 0) {
    if ($self->buffered > $self->read_limit) {
      $i = $self->read_limit-1;
    } else {
      # otherwise return "would block" and set the search index to the
      # end of the buffer so that we don't search it again
      $self->{index} = $self->buffered;
      return '0E0';
    }
  }

  # remove the line from the input buffer and reset the search
  # index.
  $_[0] = substr($self->{inbuffer},0,$i+1);  # save the line
  substr($self->{inbuffer},0,$i+1) = '';     # and chop off the rest
  $self->{index} = 0;
  return length $_[0];
}

1;


=head1 NAME

IO::LineBufferedSessionData - Handling of non-blocking line-buffered I/O

=head1 SYNOPSIS

 use IO::LineBufferedSet;
 my $set = IO::LineBufferedSet->new();
 $set->add($_) foreach ($handle1,$handle2,$handle3);

 my $line;
 while ($set->sessions) {
   my @ready = $set->wait;

   for my $h (@ready) {
     unless (my $bytes = $h->getline($line)) {  # fetch a line
       $h->close;                               # EOF or an error
       next;
     }
     next unless $bytes > 0;              # skip zero-length line
     my $result = process_data($line);    # do some processing on the line
     $line->write($result);               # write result to handle
   }

 }

=head1 DESCRIPTION

This package provides support for sets of nonblocking handles for use
in multiplexed applications.  It is used in conjunction with
IO::LineBufferedSet, and inherits from IO::SessionData.

The IO::LineBufferedSessionData object, hereafter called a "session"
for simplicity, supports a small subset of IO::Handle methods, and can
be thought of as a smart, non-blocking handle.

=head1 CONSTRUCTOR

The new() constructor is not normally called by user applications, but 
by IO::LineBufferedSet.

=head1 OBJECT METHODS

=over 4

=item $bytes = $session->read($scalar, $maxbytes [,$offset]])

The read() method acts like IO::Handle->read(), reading up to
C<$maxbytes> bytes into the scalar variable indicated by C<$scalar>.
If C<$offset> is provided, the new data will be appended to C<$scalar> 
at the position indicated.

If successful, read() will return the number of bytes read.  On
end-of-file, the method will return numeric 0.  If the read()
operation would block, the method returns 0E0 (zero but true), and on
other errors returns undef.

This is an idiom for handling the possible outcomes:

  while (1) {
    my $bytes = $session->read($data,1024);
    die "I/O error: $!" unless defined $bytes; # error
    last unless $bytes;                        # eof, leave loop
    next unless $bytes > 0;                    # would block error
    process_data($data);                       # otherwise ok
  }

=item $bytes = $session->getline($scalar);

This method has the same semantics as read() except that it returns
whole lines, observing the current value of C<$/>.  Be very alert for
the 0E0 result code (indicating that the operation would block)
because these will occur whenever a partial line is read.

Unlike <> or getline(), the result is placed in C<$scalar>, not
returned as the function result.

=item $bytes = $session->write($scalar)

This method writes the contents of C<$scalar> to the session's
internal buffer, from where it is eventually written to the handle.
As much of the data as possible is written immediately.  If not all
can be written at once, the remainder is written during one or more
subsequent calls to wait().

=item $result = $session->close()

This method closes the session, and removes itself from the list of
sessions monitored by the IO::LineBufferedSet object that owns it.
The handle may not actually be closed until sometime later, when
pending writes are finished.

Do B<not> call the handle's close() method yourself, or pending writes
may be lost.

The return code indicates whether the session was successfully closed.
Note that this will return true on delayed closes, and thus is not of
much use in detecting whether the close was actually successful.

=item $limit = $session->write_limit([$limit]

In order to prevent the outgoing write buffer from growing without
limit, you can call write_limit() to set a cap on its size.  If the
number of unwritten bytes exceeds this value, then the I<choke function>
will be invoked to perform some action.

Called with a single argument, the method sets the write limit.
Called with no arguments, returns the current value. Call with 0 to
disable the limit.

=item $coderef = $session->set_choke([$coderef])

The set_choke() method gets or sets the I<choke function>, which is
invoked when the size of the write buffer exceeds the size set by
write_limit().  Called with a coderef argument, set_choke() sets the
function; otherwise it returns its current value.

When the choke function is invoked, it will be called with two
arguments consisting of the session object and a flag indicating
whether writes should be choked or unchoked.  The function should take
whatever action is necessary, and return.  The default choke action is
to disallow further reads on the session (by calling readable() with a
false value) until the write buffer has returned to acceptable size.

Note that choking a session has no effect on the write() method, which 
can continue to append data to the buffer.

=item $session->readable($flag)

This method flags the session set that this filehandle should be
monitored for reading. C<$flag> is true to allow reads, and false
to disallow them.

=item $session->writable($flag)

This method flags the session set that this filehandle should be
monitored for writing. C<$flag> is true to allow writes, and false
to disallow them.

=back

=head1 SEE ALSO

L<IO::LineBufferedSessionSet>, L<IO::SessionData>, L<IO::SessionSet>,
L<perl>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>

=head1 COPYRIGHT

Copyright (c) 2000 Lincoln Stein. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

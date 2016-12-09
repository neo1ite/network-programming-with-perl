package IO::LineBufferedSet;
# file: IO/LineBufferedSet.pm
# Chapter 13/Appendix A: IO::LineBufferedSet Module

use strict;
use Carp;
use IO::SessionSet;
use IO::LineBufferedSessionData;
use vars '@ISA','$VERSION';

@ISA = 'IO::SessionSet';
$VERSION = '1.00';

# override SessionDataClass so that we create an IO::LineBufferedSessionData
# rather than an IO::SessionData.
sub SessionDataClass {  return 'IO::LineBufferedSessionData'; }

# override wait() in order to return sessions with pending data immediately.
sub wait {
  my $self = shift;
  # look for old buffered data first
  my @sessions = grep {$_->has_buffered_data} $self->sessions;
  return @sessions if @sessions;
  return $self->SUPER::wait(@_);
}

1;

=head1 NAME

IO::LineBufferedSet - Handling of non-blocking line-buffered I/O

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
in multiplexed applications.

=head1 CONSTRUCTOR

=over 4

=item $set = IO::LineBufferedSet->new([$listen_sock])

The new() method constructs a new IO::LineBufferedSet.  If a listening
IO::Socket object is provided in C<$listen_sock>, then the wait()
method (see below) will call accept() on this socket whenever an
incoming connection is received, and the resulting connected socket
will be added to the set.

=back

=head1 OBJECT METHODS

=over 4

=item $result = $set->add($handle [,$writeonly])

The add() method will add the handle indicated in C<$handle> to the
set of handles to be monitored.  It accepts an ordinary filehandle or
an IO::Handle (including IO::Socket).  The handle will be made
nonblocking and wrapped inside an IO::LineBufferedSessionData object,
hereafter called "sessions".

C<$writeonly>, if provided, is a flag indicating that the filehandle
is write-only.  This is appropriate when adding handles such as
STDOUT.

If successful, add() returns a true result.

=item @sessions = $set->sessions

The sessions() method returns a list of IO::LineBufferedSessionData
objects, each one corresponding to a handle either added manually with 
add(), or added automatically by wait().

=item $result = $set->delete($handle)

This method deletes the indicated handle from the monitored set.  You
may use either the handle itself, or the corresponding
IO::LineBufferedSessionData.

=item @ready = $set->wait([$timeout])

The wait() method returns the list of IO::LineBufferedSessionData
objects that are ready for reading.  Internally, the wait() method
will call accept() on the listening socket, if one was provided to the
new() method, and will attempt to complete any pending writes on
sessions.  If a timeout is provided, the method will return an empty
list if the specified time expires without a session becoming ready
for reading.  Otherwise it will block indefinitely.

Sessions are always ready for writing, since they are non-blocking.

=back

=head1 SEE ALSO

L<IO::LineBufferedSessionData>, L<IO::SessionData>, L<IO::SessionSet>,
L<perl>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>

=head1 COPYRIGHT

Copyright (c) 2000 Lincoln Stein. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

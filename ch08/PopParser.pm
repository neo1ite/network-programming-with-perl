package PopParser;
# file PopParser.pm
# Figure 8.4: The PopParser module

use strict;
use Net::POP3;
use MIME::Parser;

use vars '@ISA';
@ISA = qw(Net::POP3);

# override Net::POP3 new() method
sub new {
  my $pack   = shift;
  return unless my $self = $pack->SUPER::new(@_);
  my $parser = MIME::Parser->new;
  $parser->output_dir($ENV{TMPDIR} || '/tmp');
  $self->parser($parser);
  $self;
}

# accessor for parser()
sub parser {
  my $self = shift;
  ${*$self}{'pp_parser'} = shift if @_;
  return ${*$self}{'pp_parser'}
}

# override get()
sub get {
  my $self  = shift;
  my $msgnum = shift;
  my $fh = $self->getfh($msgnum) 
    or die "Can't get message: ",$self->message,"\n";
  return $self->parser->parse($fh);  
}

1;


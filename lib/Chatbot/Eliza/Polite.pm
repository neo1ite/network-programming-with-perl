package Chatbot::Eliza::Polite;
use Chatbot::Eliza;
use vars '@ISA';
# file: Chatbot/Eliza/Polite.pm
# Figure 12.3:  Eliza::Chatbot::Polite module

@ISA = 'Chatbot::Eliza';

# return our welcome line
sub welcome {
  my $self = shift;
  $self->botprompt($self->name . ":\t");  # Set Eliza's prompt 
  $self->userprompt("you:\t");            # Set user's prompt
  # Generate the initial greeting
  return join ('',
               $self->botprompt,
               $self->{initial}->[ int rand scalar @{ $self->{initial} } ],"\n",
               $self->userprompt);
}

# Return the response to a line of user input
sub one_line {
  my $self = shift;
  my $in = shift;
  my $reply;

  # If the user wants to quit,
  # print out a farewell and quit.
  if ( $self->_testquit($in) ) {
    $reply = $self->{final}->[ int rand scalar @{ $self->{final} } ];
    $self->{_quit}++;  # flag that we're done
    return $reply . "\n";
  }

  # Invoke the transform method
  # to generate a reply.
  $reply = $self->transform( $in );

  return join ('',
               $self->botprompt,
               $reply,"\n",
               $self->userprompt);
}

# Return true if the session is done
sub done { return shift->{_quit} }

1;

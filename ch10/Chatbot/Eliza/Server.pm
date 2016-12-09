package Chatbot::Eliza::Server;
use Chatbot::Eliza;

@ISA = 'Chatbot::Eliza';

sub command_interface {
  my $self = shift;
  my $in   = shift || \*STDIN;
  my $out  = shift || \*STDOUT;
  my ($user_input, $previous_user_input, $reply);
 
  $self->botprompt($self->name . ":\t");  # Set Eliza's prompt 
  $self->userprompt("you:\t");           # Set user's prompt

  # Print an initial greeting
  print $out $self->botprompt,
             $self->{initial}->[ int rand scalar @{ $self->{initial} } ],
             "\n";

  while (1) {
    print $out $self->userprompt;
    $previous_user_input = $user_input;
    chomp( $user_input = <$in> ); 
    last unless $user_input;

    # User wants to quit
    if ($self->_testquit($user_input) ) {
      $reply = $self->{final}->[ int rand scalar @{ $self->{final} } ];
      print $out $self->botprompt,$reply,"\n";
      last;
    } 

    # Invoke the transform method to generate a reply.
    $reply = $self->transform( $user_input );

    # Print the actual reply
    print $out $self->botprompt,$reply,"\n";
  }
}

1;

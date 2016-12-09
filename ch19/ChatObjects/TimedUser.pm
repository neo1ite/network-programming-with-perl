package ChatObjects::TimedUser;
# file: ChatObjects/TimedUser.pm
# Figure 19.8: The ChatObjects::TimedUser Module

use strict;
use ChatObjects::User;
use vars '@ISA';
@ISA = 'ChatObjects::User';

sub new {
  my $package = shift;
  my $self = $package->SUPER::new(@_);
  $self->{stillhere} = time();
  return $self
}

sub still_here {
  my $self = shift;
  $self->{stillhere} = time();  
}

sub inactivity_interval {
  my $self = shift;
  return time() - $self->{stillhere};
}

1;

__END__

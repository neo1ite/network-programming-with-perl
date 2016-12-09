package ChatObjects::Channel;
# file: ChatObjects/Channel.pm
# Figure 19.7: The ChatObjects::Channel class

use ChatObjects::User;
use ChatObjects::ChatCodes;

use overload ( '""' => 'title',
               fallback => 1
             );
my %CHANNELS;

sub new {
  my $pack  = shift;
  my ($title,$description) = @_;
  return $CHANNELS{lc $title} = bless {
                                       title       => $title,
                                       description => $description,
                                       users       => {},
                                      },$pack;
}
sub lookup   { 
  shift;  # get rid of package name
  my $title = shift;
  return $CHANNELS{lc $title};
}
sub channels { values %CHANNELS }

sub title       { shift->{title} }
sub description { shift->{description} }
sub users { values %{shift->{users}} }
sub info  {
  my $self = shift;
  my $user_count = $self->users;
  return "$self $user_count $self->{description}";
}

sub send_to_all {
  my $self = shift;
  my ($code,$data) = @_;
  $_->send($code,$data) foreach $self->users;
}

sub add { 
  my $self = shift;
  my $user = shift;
  return if $self->{users}{$user};  # already a member
  $self->send_to_all(USER_JOINS,"$self $user");
  $self->{users}{$user} = $user;
}

sub remove {
  my $self = shift;
  my $user = shift;
  return unless $self->{users}{$user};  # not already a member
  delete $self->{users}{$user};
  $self->send_to_all(USER_PARTS,"$self $user");
}

sub message {
  my $self = shift;
  my ($sender,$text) = @_;
  $self->send_to_all(PUBLIC_MSG,"$self $sender $text");
}

1;

__END__

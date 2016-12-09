package PromptUtil;
# file PromptUtil.pm
# Chapters 8,9/Appendix A: This module is used to prompt the user for passwords
# with echo off.

use strict;
require Exporter;
eval "use Term::ReadKey";

use vars '@EXPORT','@ISA';
@EXPORT = qw(get_passwd prompt);
@ISA = 'Exporter';

my $stty_settings;  # save old TTY settings

sub get_passwd {
  my ($user,$host) = @_;
  print STDERR "$user\@$host "
    if $user && $host;
  print STDERR "password: ";
  echo ('off');
  chomp(my $pass = <>);
  echo ('on');
  print STDERR "\n";
  $pass;
}

# print a prompt
sub prompt {
  local($|) = 1;
  my $prompt  = shift;
  my $default = shift;
  print "$prompt ('q' to quit) [$default]: ";
  chomp(my $response = <>);
  exit 0 if $response eq 'q';
  return $response || $default;
}

sub echo {
  my $mode = shift;
  if (defined &ReadMode) {
    ReadMode( $mode eq 'off' ? 'noecho' : 'restore' );
  } else {
    if ($mode eq 'off') {
      chomp($stty_settings = `/usr/bin/stty -g`);
      system "/usr/bin/stty -echo </dev/tty";  
    } else {
      $stty_settings =~ /^([:\da-fA-F]+)$/;
      system "/usr/bin/stty $1 </dev/tty";
    }
  }
}

1;

=head1 NAME

PromptUtil - Prompt utilities

=head1 SYNOPSIS

  use PromptUtil;

  my $response = prompt('<n>ext, <p>revious, or <e>dit','n');
  my $pass     = get_passwd();

=head1 DESCRIPTION

This package exports two utilities that are handy for prompting for
user input.

=head1 EXPORTED FUNCTIONS

=over 4

=item $result = prompt($prompt,$default)

Prints the indicated C<$prompt> to and requests a line of input.  If
the user types "q" or "quit" returns false.  Otherwise returns the
input line (minus the newline).  If the user hits return without
typing anything, returns the default specified by C<$default>.

=item $password = get_passwd([$user,$host])

Turns off terminal echo and prompts the user to enter his password.
If C<$user> and C<$host> are provided, the prompt is in the format

 jdoe@host.domain password:

otherwise the prompt is simply

 password:

The function returns the password, or undef it the user typed return
without entering a password.

=back

If get_passwd() detects that the Term::ReadKey module is available, it
will attempt to use that.  Otherwise it will call the Unix stty
program, which will not be available on non-Unix systems.

=head1 SEE ALSO

L<Term::ReadKey>, L<perl>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>

=head1 COPYRIGHT

Copyright (c) 2000 Lincoln Stein. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

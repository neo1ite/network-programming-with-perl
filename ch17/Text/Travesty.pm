package Text::Travesty;
# Chapter 17/Appendix A: The Text::Travesty module implements "travesty",
# a Markov chain algorithm that analyzes a text document and generates a 
# new document that preserves all the word-pair frequencies of the original.

use strict;
use Text::Wrap qw(fill);
use IO::File;

sub new {
  my $pack = shift;
  return bless {
                words  => [],
                lookup => {},
                num    => {},
                a => '', p=> '', n=>'',
               },$pack;
}

sub add {
  my $self = shift;
  my $string = shift;
  my ($words,$lookup,$num,$a,$p,$n) = 
    @{$self}{qw(words lookup num a p n)};
  for my $w (split /\s+/,$string) {
    ($a,$p) = ($p,$n);
    unless (defined($n = $num->{$w})) {
      push @{$words},$w;
      $n = pack 'S',$#$words;
      $num->{$w} = $n;
    }
    $lookup->{"$a$p"} .= $n;
  }
  @{$self}{'a','p','n'} = ($a,$p,$n);
}

sub analyze_file {
  my $self = shift;
  my $file = shift;
  unless (defined (fileno $file)) {
    $file = IO::File->new($file) || croak("Couldn't open $file: $!\n");
  }
  $self->add($_) while defined ($_ = <$file>);
}

sub generate {
  my $self = shift;
  my $word_count = shift || 1000;

  my ($words,$lookup,$a,$p) = @{$self}{qw(words lookup a p)};
  my ($n,$foo,$result);
  while ($word_count--) {
    $n = $lookup->{"$a$p"};
    ($foo,$n) = each(%$lookup) if $n eq '';
    $n = substr($n,int(rand(length($n))) & 0177776,2);
    ($a,$p) = ($p,$n);
    my $w = unpack('S',$n);
    $w = $words->[$w];
    $result .= $w;
    $result .= $w =~ /\.$/ && rand() < .1 ? "\n\n"  : ' ';
  }
  @{$self}{qw(a p)} = ($a,$p);
  return $result;
}

sub words {
  return @{shift->{words}};
}

sub pretty_text {
  my $self = shift;
  my $text = $self->generate(@_);
  return fill("\t",'',$text) . "\n";
}

sub reset {
  my $self= shift;
  @{$self}{qw(lookup num)} = ({},{});
  $self->{words}  = [];
  delete $self->{a};
  delete $self->{p};
}

1;


=head1 NAME

Text::Travesty - Turn text into a travesty

=head1 SYNOPSIS

  use Text::Travesty

  my $travesty = Text::Travesty->new;
  $travesty->analyze_file('for_whom_the_bell_tolls.txt');
  print $travesty->generate(1000);

=head1 DESCRIPTION

This module uses the travesty algorithm to construct a Markov Chain of
human-readable text and spew out stylistically similar (but entirely
meaningless) text that has the same word frequency characteristics.

=head1 CONSTRUCTOR

=over 4

=item $travesty = Text::Travesty->new

The new() method constructs a new Text::Travesty object with empty
frequency tables.  You will typically call add() or analyze_file() one
or more times to add text to the frequency tables.

=back

=head1 OBJECT METHODS

=over 4

=item $travesty->add($text);

This method splits the provided text into words and adds them to the
internal frequency tables.  You will typically call add() multiple
times during the analysis of a longer text.

The definition of "words" is a bit unusual, because it includes
punctuation and other non-whitespace characters.  The
pseudo-punctuation makes the generated travesties more fun.

=item $travesty->analyze_file($file)

This method adds the entire contents of the indicated file to the
frequency tables.  C<$file> may be an opened filehandle, in which case
analyze_file() reads its contents through to EOF, or a file path, in
which case the method opens it for reading.

=item $text = $travesty->generate([$count])

The generate() method will spew back a travesty of the input text
based on a Markov model built from the word frequency tables.
C<$count>, if provided, gives the length of the text to generate in
words.  If not provided, the count defaults to 1000.

=item $text = $travesty->pretty_text([$count])

This method is similar to generate() except that the returned text is
formatted into wrapped paragraphs.

=item @words = $travesty->words

This method returns a list of all the unique words in the frequency
tables.  Punctuation and capitalization count for uniqueness.

=item $travesty->reset

Reset the travesty object, clearing out its frequency tables and
readying it to accept a new text to analyze.

=back

=head1 SEE ALSO

L<Text::Wrap>, L<IO::File>, L<perl>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>

=head1 COPYRIGHT

Copyright (c) 2000 Lincoln Stein. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

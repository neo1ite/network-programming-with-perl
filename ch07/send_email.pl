# Figure 7.2: A simple subroutine for sending e-mail

use Net::SMTP;

sub mail {
  my ($msg,$server) = @_;

  # parse the message to get sender and recipient
  my ($header,$body) = split /\n\n/,$msg,2;
  return warn "no header" unless $header && $body;

  # fold continuation lines
  $header =~ s/\n\s+/ /gm;

  # parse fields
  my (%fields) = $header =~ /([\w-]+):\s+(.+)$/mg;
  my $from = $fields{From}                 or return warn "no From field";
  my @to   = split /\s*,\s*/,$fields{To}   or return warn "no To field";
  push @to,split /\s*,\s*/,$fields{Cc}     if $fields{Cc};

  # open server
  my $smtp = Net::SMTP->new($server)          or return warn "couldn't open server";
  $smtp->mail($from)                          or return warn $smtp->message;
  my @ok = $smtp->recipient(@to,{SkipBad=>1}) or return warn $smtp->message;
  warn $smtp->message unless @ok == @to;
  $smtp->data($msg)                           or return warn $smtp->message;
  $smtp->quit;
}

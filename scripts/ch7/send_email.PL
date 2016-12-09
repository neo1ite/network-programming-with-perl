#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl} -w
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

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
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

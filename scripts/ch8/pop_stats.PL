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
# file: pop_stats.pl
# Figure 8.1: List entries in a user's inbox

use strict;
use Net::POP3;
use Mail::Header;
use PromptUtil;

my ($user,$host) = split(/\@/,shift,2);
($user && $host) or die "Usage: pop_stats.pl username\@mailbox.host\n";
my $passwd = get_passwd($user,$host) || exit 0;

my $pop = Net::POP3->new($host,Timeout=>30) or die "Can't connect to $host: $!\n";
my $messages = $pop->login($user=>$passwd)  or die "Can't log in: ",$pop->message,"\n";
my $last     = $pop->last;
$messages += 0;
print "inbox has $messages messages (",$messages-$last," new)\n";

for my $msgnum ($last+1 .. $messages) {
  my $header         = $pop->top($msgnum);
  my $parsedhead     = Mail::Header->new($header);
  chomp (my $subject = $parsedhead->get('Subject'));
  chomp (my $from    = $parsedhead->get('From'));
  $from = clean_from($from);
  printf "%4d %-25s %-50s\n",$msgnum,$from,$subject;
}
$pop->quit;

sub clean_from {
  local $_ = shift;
  /^"([^\"]+)" <\S+>/ && return $1;
  /^([^<>]+) <\S+>/   && return $1;
  /^\S+ \(([^\)]+)\)/ && return $1;
  return $_;
}

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

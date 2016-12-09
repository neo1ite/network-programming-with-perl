#!/usr/bin/perl
# file: imap_stats.pl
# Figure 8.5: Summarize an IMAP mailbox

use strict;
use Net::IMAP::Simple;
use Mail::Header;
use PromptUtil;

my ($user,$host) = split(/\@/,shift,2);
my $mailbox      = shift || 'INBOX';
($user && $host) or die "Usage: imap_stats.pl username\@mailbox.host [mailbox]\n";
my $passwd = get_passwd($user,$host) || exit 0;

$/ = "\015\012";
my $imap = Net::IMAP::Simple->new($host,Timeout=>30) or die "Can't connect to $host: $!\n";
defined($imap->login($user=>$passwd))           or die "Can't log in\n";
defined(my $messages = $imap->select($mailbox)) or die "invalid mailbox\n";
my $last     = $imap->last;

print "$mailbox has $messages messages (",$messages-$last," new)\n";

for my $msgnum (1..$messages) {
  my $header         = $imap->top($msgnum);
  my $parsedhead     = Mail::Header->new($header);
  chomp (my $subject = $parsedhead->get('Subject'));
  chomp (my $from    = $parsedhead->get('From'));
  $from = clean_from($from);
  my $read = $imap->seen($msgnum) ? 'read' : 'unread';
  printf "%4d %-25s %-40s %-10s\n",$msgnum,$from,$subject,$read;
}
$imap->quit;

sub clean_from {
  local $_ = shift;
  /^"([^\"]+)" <\S+>/ && return $1;
  /^([^<>]+) <\S+>/   && return $1;
  /^\S+ \(([^\)]+)\)/ && return $1;
  return $_;
}

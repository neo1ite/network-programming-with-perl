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
# file: scan_newsgroups.pl
# Figure 8.9: Scan newsgroups for articles with subject lines matching patterns

use strict;
BEGIN { @AnyDBM_File::ISA = qw(DB_File GDBM_File NDBM_File SDBM_File) }
use AnyDBM_File;
use Getopt::Long;
use Net::NNTP;
use MIME::Entity;
use Fcntl;

#constants
use constant NEWSCACHE => "$ENV{HOME}/.newscache";
use constant USAGE => <<END;
Usage: scan_newsgroups.pl [options] newsgroup1 newsgroup2...
  Scan newsgroups for articles with subject lines matching patterns.
 Options:
      -mailto  <addr>   E-mail address to send matching articles to
      -subject <pat>    Pattern(s) to match subject lines on
      -server  <host>   NNTP server
      -insensitive      Case-insensitive matches
      -all              Send all articles (default: send unseen ones)
      -verbose          Verbose progress reports
  Options can be abbreviated to the smallest unique identifier, for example -i -su.
END

# globals
my ($RECIPIENT,$SERVER,$SEND_ALL,$NOCASE,$VERBOSE,@SUBJ_PATTERNS,@NEWSGROUPS);
my (%Seen,%Articles,@Fields);

GetOptions('mailto:s'   => \$RECIPIENT,
           'server:s'   => \$SERVER,
           'subject:s'  => \@SUBJ_PATTERNS,
           'insensitive'=> \$NOCASE,
           'all'        => \$SEND_ALL,
           'verbose'    => \$VERBOSE,
          ) or die USAGE;
(@NEWSGROUPS = @ARGV) or die "Must provide at least one newsgroup pattern.\n",USAGE;
@SUBJ_PATTERNS        or die "Must provide at least one subject pattern.\n",USAGE;
$RECIPIENT            ||= $ENV{USER} || $ENV{LOGNAME};

# open NNTP connection
my $nntp = Net::NNTP->new($SERVER) or die "Can't connect to server: $!";

# open/initialize database of cached messages
tie(%Seen,'AnyDBM_File',NEWSCACHE,O_RDWR|O_CREAT,0640) 
  or die "Can't open article cache: $!";

# compile the pattern matching code
my $patmatch = match_code(@SUBJ_PATTERNS);

# expand the newsgroup patterns
my @groups = expand_newsgroups($nntp,@NEWSGROUPS);

# search groups - results are accumulated in %Articles
grep_group($nntp,$_,$patmatch) foreach @groups;

# find the unseen ones
my @to_fetch = grep {!$Seen{$_}++ || $SEND_ALL} keys %Articles;
warn scalar keys %Articles,' articles, ',scalar @to_fetch," unseen\n" if $VERBOSE;

# send out the messages
send_mail($nntp,\@to_fetch);
$nntp->quit;
exit 0;

# construct a coderef that matches one or more patterns
sub match_code {
  my @patterns = @_;
  my $flags = $NOCASE ? 'i' : '';
  my $code = "sub { my \$t = shift;\n";
  $code .= "        my \$matched = 1;\n";
  $code .= "        \$matched &&= \$t=~/$_/$flags;\n" foreach @patterns;
  $code .= "        return \$matched;\n }\n";
  return eval $code or die $@;
}

# expand wildcard patterns in newsgroups
sub expand_newsgroups {
  my ($nntp,@patterns) = @_;
  my %g;
  foreach (@patterns) {
    $g{$_}++ and next unless /\*\[\]\?/;
    next unless my $g = $nntp->newsgroups($_);
    $g{$_}++ foreach keys %$g;
  }
  return keys %g;
}

# search named group for articles with matching subject lines
sub grep_group {
  my ($nntp,$group,$match_sub) = @_;
  my $matched = 0;
  warn "Searching $group for matches\n" if $VERBOSE;

  my $overview = get_overview($nntp,$group);
  for my $o (values %$overview) {
    my ($subject,$msgID) = @{$o}{'Subject','Message-ID'};
    next unless $match_sub->($subject);
    $Articles{$msgID} = $o;
    $matched++;
  }

  warn "found $matched matching articles\n" if $VERBOSE;
  return $matched;
}

# get overview from group as a hash of hashes
sub get_overview {
  my ($nntp,$group) = @_;
  warn "Fetching overview for $group\n" if $VERBOSE;

  return unless my ($count,$first,$last) = $nntp->group($group);
  @Fields = map {/([\w-]+):/&& $1} @{$nntp->overview_fmt} unless @Fields;

  my $over   = $nntp->xover([$first,$last]) || return;
  foreach (keys %$over) { 
    my $h = {};
    @{$h}{@Fields,'Message-Number'}= (@{$over->{$_}},"$group:$_"); 
    $over->{$_} = $h;
  }

  return $over;
}

# construct mail to recipient
sub send_mail {
  my ($nntp,$to_fetch) = @_;
  my $count = @$to_fetch;
  my $date = localtime;

  warn "sending e-mail message to $RECIPIENT\n" if $VERBOSE;

  # start the MIME message
  my $message = <<END;
Newsgroups searched: @NEWSGROUPS
Pattern(s):          @SUBJ_PATTERNS
Articles matched:    $count

END
  my $mail = MIME::Entity->build(Subject => "Newsgroup postings $date",
                                 To       => $RECIPIENT,
                                 Type     => 'text/plain',
                                 Encoding => '7bit',
                                 Data     => $message,
                                );
  attach_article($nntp,$mail,$_) foreach @$to_fetch;
  $mail->smtpsend or die "Can't send mail: $!";
  $mail->purge;
}

# attach a named article to message
sub attach_article {
  my ($nntp,$mail,$messID) = @_;
  my $article   = $nntp->article($messID) || return;
  $mail->attach(Type         => 'message/rfc822',
                Description  => $Articles{$messID}{Subject},
                Filename     => $Articles{$messID}{'Message-Number'},
                Encoding     => '7bit',
                Data         => $article);
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

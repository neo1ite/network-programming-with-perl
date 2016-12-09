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
# file: timed_chat_server.pl
# Figure 19.10: chat_server.pl with periodic checks for defunct clients

use strict;
use ChatObjects::ChatCodes;
use ChatObjects::Comm;
use ChatObjects::TimedUser;
use ChatObjects::Channel;

use constant DEBUG          => 1;
use constant AUTO_LOGOUT    => 120;  # auto-logout if silent for two minutes
use constant CHECK_INTERVAL =>  30;  # prune silent users every 30 sec

# create a bunch of channels
ChatObjects::Channel->new('CurrentEvents',  'Discussion of current events');
ChatObjects::Channel->new('Weather',        'Talk about the weather');
ChatObjects::Channel->new('Gardening',      'For those with the green thumb');
ChatObjects::Channel->new('Hobbies',        'For hobbyists of all types');
ChatObjects::Channel->new('Pets',           'For our furry and feathered friends');

# dispatch table
my %DISPATCH = (
                LOGOFF()        => 'logout',
                JOIN_REQ()      => 'join',
                PART_REQ()      => 'part',
                SEND_PUBLIC()   => 'send_public',
                SEND_PRIVATE()  => 'send_private',
                LIST_CHANNELS() => 'list_channels',
                LIST_USERS()    => 'list_users',
                STILL_HERE()    => 'still_here',
                );

# create the UDP socket
my $port = shift || 2027;
my $server = ChatObjects::Comm->new(LocalPort=>$port);
warn "servicing incoming requests...\n";

my $next_check = time() + CHECK_INTERVAL;

while (1) {
  next unless my ($code,$msg,$addr) = $server->recv_event;

  warn "$code $msg\n" if DEBUG;
  do_login($addr,$msg,$server) && next if $code == LOGIN_REQ;

  my $user = ChatObjects::TimedUser->lookup_byaddr($addr);
  $server->send_event(ERROR,"please log in",$addr) && next 
    unless defined $user;

  $server->send_event(ERROR,"unimplemented event code",$addr) && next 
    unless my $dispatch = $DISPATCH{$code};
  $user->$dispatch($msg);
} continue {
  if (time() > $next_check) {
    auto_logoff();
    $next_check = time() + CHECK_INTERVAL;
  }
}

sub auto_logoff {
  warn "Inactivity check...\n" if DEBUG;
  foreach (ChatObjects::TimedUser->users) {
    next if $_->inactivity_interval < AUTO_LOGOUT;
    warn "Autologout of $_\n" if DEBUG;
    $_->logout;
  }
}

sub do_login {
  my ($addr,$nickname,$server) = @_;
  return $server->send_event(ERROR,"nickname already in use",$addr) 
    if ChatObjects::TimedUser->lookup_byname($nickname);
  return unless ChatObjects::TimedUser->new($addr,$nickname,$server);
}

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

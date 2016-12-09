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
# Figure 7.6: Sending an audio attachment with MIME tools
# file: simple_mime.pl

use strict;
use MIME::Entity;

# create top-level entity
my $msg = MIME::Entity->build(From    => 'lstein@lsjs.org',
                              To      => 'jdoe@acme.org',
                              Subject => 'Greetings!',
                              Type    => 'multipart/mixed');

# attach a message
my $greeting = <<END;
Hi John,

Here is a little something for you to listen to.

Enjoy!  
L
END

$msg->attach(Type     => 'text/plain',
             Encoding => '7bit',
             Data     => $greeting);

# attach the audio file
$msg->attach(Type        => 'audio/wav',
             Encoding    => 'base64',
             Description => 'Picard saying "You will be assimilated"',
             Path        => "$ENV{HOME}/News/sounds/assimilated.wav");

# attach signature
$msg->sign(File=>"$ENV{HOME}/.signature");

# and send it off using "smtp"
$msg->send('smtp');

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

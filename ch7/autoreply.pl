#!/usr/bin/perl
# file: autoreply.pl
# Figure 7.4: An autoreply program

use strict;
use Mail::Internet;

use constant HOME    => (getpwuid($<))[7];
use constant USER    => (getpwuid($<))[0];
use constant MSGFILE => HOME . "/.vacation";
use constant SIGFILE => HOME . "/.signature";

exit 0 unless -e MSGFILE;
exit 0 unless my $msg = Mail::Internet->new(\*STDIN);

my $header = $msg->head;
# no reply unless message is directed To: us
my $myname = USER;
exit 0 unless $header->get('To') =~ /$myname/;

# no reply if message is marked as "Bulk"
exit 0 if $header->get('Precedence') =~ /bulk/i;

# no reply if the From line contains Daemon, Postmaster, Root or ourselves
exit 0 if $header->get('From') =~ /subsystem|daemon|postmaster|root|$myname/i;

# no reply if the Subject line is "returned mail"
exit 0 if $header->get('Subject') =~ /(returned|bounced) mail/i;

# OK, we can generate the reply now
my $reply = $msg->reply;

# Open the message file for the reply
open (V,MSGFILE) or die "Can't open message file: $!";

# Prepend the reply message lines
my $body = $reply->body;
unshift (@$body,<V>,"\n");

# add the signature
$reply->add_signature(SIGFILE);

# send the mail out
$reply->send or die;

#!/usr/bin/perl
# file: mailtools1.pl
# Figure 7.3: Sending e-mail with Mail::Internet

use Mail::Internet;

my $head = Mail::Header->new;
$head->add(From => 'John Doe <doe@acme.org>');
$head->add(To   => 'L Stein <lstein@lsjs.org>');
$head->add(Cc   => 'jac@acme.org');
$head->add(Cc   => 'vvd@acme.org');
$head->add(Subject => 'hello there');

my $body = <<END;
This is just a simple e-mail message.
Nothing to get excited about.

Regards, JD
END

$mail = Mail::Internet->new(Header => $head,
                            Body   => [$body],
                            Modify => 1);
print $mail->send('sendmail');

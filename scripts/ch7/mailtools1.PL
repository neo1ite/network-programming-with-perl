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
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

#!/usr/bin/perl -w
# file: mail_recent.pl
# Figure 7.9: Combining MIME attachments and Net::FTP

use strict;
use Net::FTP;
use MIME::Entity;

use constant HOST   => 'ftp.perl.org';
use constant DIR    => '/pub/CPAN';
use constant RECENT => 'RECENT';
use constant MAILTO => 'lstein';
use constant DEBUG  => 1;

my %RETRIEVE;
my $TMPDIR = $ENV{TMPDIR} || '/usr/tmp';

warn "logging in\n" if DEBUG;

my $ftp = Net::FTP->new(HOST) or die "Couldn't connect: $@\n";
$ftp->login('anonymous')      or die $ftp->message;
$ftp->cwd(DIR)                or die $ftp->message;

# Get the RECENT file
warn "fetching RECENT file\n" if DEBUG;
my $fh = $ftp->retr(RECENT) or die $ftp->message;
while (<$fh>) {
  chomp;
  $RETRIEVE{$1} = $_ if m!^modules/by-module/.+/([^/]+\.tar\.gz)$!;
}
$fh->close;

my $count = keys %RETRIEVE;
my $message = "Please find enclosed $count recent modules submitted to CPAN.\n\n";

# start the MIME message
my $mail = MIME::Entity->build(Subject => 'Recent CPAN submissions',
                               To       => MAILTO,
                               Type     => 'text/plain',
                               Encoding => '7bit',
                               Data     => $message,
                              );

# get each of the named files and turn them into an attachment
for my $file (keys %RETRIEVE) {
  my $remote_path = $RETRIEVE{$file};
  my $local_path  = "$TMPDIR/$file";
  warn "retrieving $file\n" if DEBUG;
  $ftp->get($remote_path,$local_path) or warn($ftp->message ) and next;
  $mail->attach(Path        => $local_path,
                Encoding    => 'base64',
                Type        => 'application/x-gzip',
                Description => $file,
                Filename    => $file);
}

$mail->sign(File => "$ENV{HOME}/.signature") if -e "$ENV{HOME}/.signature";

warn "sending mail\n" if DEBUG;
$mail->send('smtp');
$mail->purge;

$ftp->quit;

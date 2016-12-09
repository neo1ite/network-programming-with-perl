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
# file mirror_images.pl
# Figure 9.21: Mirroring images from remote pages

use strict;
use LWP;
use PromptUtil;
use HTTP::Cookies;
use HTML::Parser;
use URI;

use vars '@ISA';
@ISA = 'LWP::UserAgent';

my $agent    = __PACKAGE__->new;
$agent->cookie_jar(HTTP::Cookies->new(file=>"$ENV{HOME}/.lwp-cookies",autosave=>1));

while (my $url = shift) {
  my $request  = HTTP::Request->new(GET => $url);

  my $parser = HTML::Parser->new(api_version => 3);
  $parser->handler(start => \&start,'self,tagname,attr');

  my $response = $agent->request($request, 
                                 sub {
                                   my ($data,$response,$protocol) = @_;
                                   die "Not an HTML file\n" unless $response->content_type eq 'text/html';
                                   $parser->{base}  ||= $response->base;
                                   $parser->{agent} ||= $agent;
                                   $parser->parse($data);
                                 }
                                );

  warn "$url: ",$response->header('X-Died'),"\n"  if $response->header('X-Died');
  warn "$url: ",$response->message,"\n"           if !$response->is_success;
}

sub start {
  my ($parser,$tag,$attr) = @_;
  return unless $tag eq 'img';
  return unless my $url = $attr->{src};
  # use the URI class to resolve relative links
  my $remote_name  = URI->new_abs($url,$parser->{base});
  my ($local_name) = $url =~ m!([^/]+)$!;
  my $response = $parser->{agent}->mirror($remote_name,$local_name);
  print STDERR "$local_name: ",$response->message,"\n";
}

sub get_basic_credentials {
  my ($self,$realm,$uri) = @_;
  print STDERR "Enter username and password for realm \"$realm\".\n";
  print STDERR "username: ";
  chomp (my $name = <>);
  return unless $name;
  my $passwd = get_passwd();
  return ($name,$passwd);
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

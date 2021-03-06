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
# file: ftp_mirror.pl
# Figure 6.2: Recursively mirroring an FTP directory

use strict;
use Net::FTP;
use File::Path;
use Getopt::Long;

use constant USAGEMSG => <<USAGE;
Usage: ftp_mirror.pl [options] host:/path/to/directory
Options: 
        --user  <user>  Login name
        --pass  <pass>  Password
        --hash          Progress reports
        --verbose       Verbose messages
USAGE

my ($USERNAME,$PASS,$VERBOSE,$HASH);

die USAGEMSG unless GetOptions('user=s'  => \$USERNAME,
                               'pass=s'  => \$PASS,
                               'hash'    => \$HASH,
                               'verbose' => \$VERBOSE);
die USAGEMSG unless my ($HOST,$PATH) = $ARGV[0]=~/(.+):(.+)/;

my $ftp = Net::FTP->new($HOST) or die "Can't connect: $@\n";
$ftp->login($USERNAME,$PASS)   or die "Can't login: ",$ftp->message;
$ftp->binary;
$ftp->hash(1) if $HASH;

do_mirror($PATH);

$ftp->quit;
exit 0;

# top-level entry point for mirroring.
sub do_mirror {
  my $path = shift;

  return unless my $type = find_type($path);

  my ($prefix,$leaf) = $path =~ m!^(.*?)([^/]+)/?$!;
  $ftp->cwd($prefix) if $prefix;

  return get_file($leaf)  if $type eq '-';  # ordinary file
  return get_dir($leaf)   if $type eq 'd';  # directory

  warn "Don't know what to do with a file of type $type. Skipping.";
}

# mirror a file
sub get_file {
  my ($path,$mode) = @_;
  my $rtime = $ftp->mdtm($path);
  my $rsize = $ftp->size($path);
  $mode = (parse_listing($ftp->dir($path)))[2] unless defined $mode;

  my ($lsize,$ltime) = stat($path) ? (stat(_))[7,9] : (0,0);
  if ( defined($rtime) and defined($rsize) 
       and ($ltime >= $rtime) 
       and ($lsize == $rsize) ) {
    warn "Getting file $path: not newer than local copy.\n" if $VERBOSE;
    return;
  }

  warn "Getting file $path\n" if $VERBOSE;
  $ftp->get($path) or (warn $ftp->message,"\n" and return);
  chmod $mode,$path if $mode;
}

# mirror a directory, recursively
sub get_dir {
  my ($path,$mode) = @_;
  my $localpath = $path;
  -d $localpath or mkpath $localpath or die "mkpath failed: $!";
  chdir $localpath                   or die "can't chdir to $localpath: $!";
  chmod $mode,'.' if $mode;

  my $cwd = $ftp->pwd                or die "can't pwd: ",$ftp->message;
  $ftp->cwd($path)                   or die "can't cwd: ",$ftp->message;

  warn "Getting directory $path/\n" if $VERBOSE;

  foreach ($ftp->dir) {
    next unless my ($type,$name,$mode) = parse_listing($_);
    next if $name =~ /^(\.|\.\.)$/;  # skip . and ..
    get_dir ($name,$mode)    if $type eq 'd';
    get_file($name,$mode)    if $type eq '-';
    make_link($name)         if $type eq 'l';
  }

  $ftp->cwd($cwd)     or die "can't cwd: ",$ftp->message;
  chdir '..';
}

# subroutine to determine whether a path is a directory or a file
sub find_type {
  my $path = shift;
  my $pwd = $ftp->pwd;
  my $type = '-';  # assume plain file
  if ($ftp->cwd($path)) {
    $ftp->cwd($pwd);
    $type = 'd';
  }
  return $type;
}

# Attempt to mirror a link.  Only works on relative targets.
sub make_link {
  my $entry = shift;
  my ($link,$target) = split /\s+->\s+/,$entry;
  return if $target =~ m!^/!;
  warn "Symlinking $link -> $target\n" if $VERBOSE;
  return symlink $target,$link;
}

# parse directory listings 
# -rw-r--r--   1 root     root          312 Aug  1  1994 welcome.msg
sub parse_listing {
  my $listing = shift;
  return unless my ($type,$mode,$name) =
    $listing =~ /^([a-z-])([a-z-]{9})  # -rw-r--r--
                 \s+\d*                # 1
                 (?:\s+\w+){2}         # root root
                 \s+\d+                # 312
                 \s+\w+\s+\d+\s+[\d:]+ # Aug 1 1994
                 \s+(.+)               # welcome.msg
                 $/x;           
  return ($type,$name,filemode($mode));
}

# turn symbolic modes into octal
sub filemode {
  my $symbolic = shift;
  my (@modes) = $symbolic =~ /(...)(...)(...)$/g;
  my $result;
  my $multiplier = 1;
  while (my $mode = pop @modes) {
    my $m = 0;
    $m += 1 if $mode =~ /[xsS]/;
    $m += 2 if $mode =~ /w/;
    $m += 4 if $mode =~ /r/;
    $result += $m * $multiplier if $m > 0;
    $multiplier *= 8;
  }
  $result;
}
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

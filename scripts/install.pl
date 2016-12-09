#!/usr/bin/perl

use Config;
use File::Copy 'move';
use File::Path 'mkpath';
use File::Basename;
use File::stat;
my $COUNT = 10;

my $dest = shift || $Config{installscript};
-d $dest || mkpath($dest) || die "Couldn't make path $dest: $!\n";
warn "INSTALLING SCRIPTS IN $dest.  HIT CONTROL-C NOW TO ABORT.\n";
warn "COUNTING DOWN FROM $COUNT\n";
for (1..$COUNT) {
  warn $COUNT+1-$_,"...\n";
  sleep 1;
}

foreach (glob('ch*/*.PL')) {
  (my $script = $_) =~ s/\.PL$/.pl/;
  system "perl $_";
  die "Couldn't do variable substitutions on $_" unless -e $script;
  my $st = stat($script);
  move($script,$dest) or die "Couldn't copy: $!\n";
  my $base = basename($script);
  chmod $st->mode, "$dest/$base" or die "shit: $!";
}

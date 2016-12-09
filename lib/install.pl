#!/usr/bin/perl

use strict;
use File::Find 'find';
use File::Path 'mkpath';
use File::Copy 'copy';
use File::Basename 'dirname';
use Config;

my $DEST        = shift || $Config{sitelib};

find (\&process,'.');

sub process {
  return unless /\.pm$/;
  my $name = $_;
  my $dest = "$DEST/$File::Find::dir";
  -d $dest || warn("creating $dest\n") && mkpath($dest);
  if (copy($name,"$dest/$name")) {
    warn "$name -> $dest/$name\n";
  } else {
    warn "Couldn't install $File::Find::name: $!\n";
  }
  1;
}

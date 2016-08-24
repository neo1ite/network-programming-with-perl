#!/usr/bin/perl

sub filecount {
    my $dirname = shift;
    my $cmd = <<"    CMD";
        count="\$(find $dirname -type f 2>/dev/null | wc -l)"
        printf "$dirname: %s\n" \$count
    CMD
    exec $cmd;
}

my @children;
for my $dir (grep -d, glob 'Programming') {
    my $child = fork // die "couldn't fork process: $!";
    filecount $dir if $child == 0;
    push @children, $child;
}

join $_ for @children;

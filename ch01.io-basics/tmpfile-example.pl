
use IO::File;
$F = IO::File;
$fh = $F->new_tmpfile;
$fh->say($_) for qw(foo bar baz bof faz mac pac);
$fh->seek(0, SEEK_SET);
print while <$fh>;

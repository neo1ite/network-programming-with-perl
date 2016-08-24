# parent process id - ID of process that started this one
$pid = getppid();

# pid - current process id special variable
$$;

# process group id - typically the id of the very first (top level) process to kick off subprocesses
$processid = getpgrp($$); # this process' group
$pgrp = getpgrp($pid); # some other process' group

# system - starts system process and returns process' exit status
$status = system qw(some command here);
$status = system "some command here";

# exec - replaces this process with the given system process
$status exec qw(some command here);
$status exec 'some command here';
die "this won't happen if the process is good: $! ; $status";

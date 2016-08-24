# to get around buffering: 2 choices
FH->autoflush(1); # autoflush mode
$bytes = FH->syswrite($data, $length, $offset); # syswrite goes straight to system IO
FH->sysread($buffer, $length, $offset); # fetches directly from system IO

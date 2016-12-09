#!/usr/bin/perl
# file: wrap_cli.pl
# Figure 22.2: wrap_cli.pl, the text formatting client

use IO::Socket;
use Getopt::Long;

use constant SOCK_PATH     => '/tmp/wrapserv';

my $path;
GetOptions("path=s" => \$path);
$path ||= SOCK_PATH;

my $sock = IO::Socket::UNIX->new($path) or die "Socket: $!";
warn "Connected to $path...\n";

my @lines = <>;  # slurp lines
print $sock @lines;
$sock->shutdown(1);   # close socket for writing
print STDOUT <$sock>; # display the result

__END__


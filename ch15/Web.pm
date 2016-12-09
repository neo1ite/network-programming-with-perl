package Web;
# file: Web.pm
# Figure 15.1: Core Web Server Routines

# utility routines for a minimal web server.
# handle_connection() and docroot() are only exported functions

use strict;
use vars '@ISA','@EXPORT';
require Exporter;

@ISA = 'Exporter';
@EXPORT = qw(handle_connection docroot);

my $DOCUMENT_ROOT = '/home/www/htdocs';
my $CRLF = "\015\012";

sub handle_connection {
  my $c = shift;   # socket
  my ($fh,$type,$length,$url,$method);
  local $/ = "$CRLF$CRLF";   # set end-of-line character
  my $request = <$c>;        # read the request header

  return invalid_request($c) 
    unless ($method,$url) = $request =~ m!^(GET|HEAD) (/.*) HTTP/1\.[01]!;
  return not_found($c) unless ($fh,$type,$length) = lookup_file($url);
  return redirect($c,"$url/") if $type eq 'directory';

  # print the header
  print $c "HTTP/1.0 200 OK$CRLF";
  print $c "Content-length: $length$CRLF";
  print $c "Content-type: $type$CRLF";
  print $c $CRLF;

  return unless $method eq 'GET';

  # print the content
  my $buffer;
  while ( read($fh,$buffer,1024) ) {
    print $c $buffer;
  }
  close $fh;
}

sub lookup_file {
  my $url = shift;
  my $path = $DOCUMENT_ROOT . $url;               # turn into a path
  $path =~ s/\?.*$//;                             # get rid of query
  $path =~ s/\#.*$//;                             # get rid of fragment
  $path .= 'index.html' if $url=~m!/$!;           # get index.html if path ends in /
  return if $path =~ m!/\.\./!;                   # don't allow relative paths (..)
  return (undef,'directory',undef) if -d $path;   # oops! a directory
  my $type = 'text/plain';                        # default MIME type
  $type = 'text/html'  if $path =~ /\.html?$/i;   # HTML file?
  $type = 'image/gif'  if $path =~ /\.gif$/i;     # GIF?
  $type = 'image/jpeg' if $path =~ /\.jpe?g$/i;   # JPEG?
  return unless my $length = (stat(_))[7];        # file size
  return unless my $fh = IO::File->new($path,"<");   # try to open file
  return ($fh,$type,$length);
}

sub redirect {
  my ($c,$url) = @_;
  my $host = $c->sockhost;
  my $port = $c->sockport;
  my $moved_to = "http://$host:$port$url";
  print $c "HTTP/1.0 301 Moved permanently$CRLF";
  print $c "Location: $moved_to$CRLF";
  print $c "Content-type: text/html$CRLF$CRLF";
  print $c <<END;
<HTML>
<HEAD><TITLE>301 Moved</TITLE></HEAD>
<BODY><H1>Moved</H1>
<P>The requested document has moved
<A HREF="$moved_to">here</A>.</P>
</BODY>
</HTML>
END
}

sub invalid_request {
  my $c = shift;
  print $c "HTTP/1.0 400 Bad request$CRLF";
  print $c "Content-type: text/html$CRLF$CRLF";
  print $c <<END;
<HTML>
<HEAD><TITLE>400 Bad Request</TITLE></HEAD>
<BODY><H1>Bad Request</H1>
<P>Your browser sent a request that this server 
does not support.</P>
</BODY>
</HTML>
END
}

sub not_found {
  my $c = shift;
  print $c "HTTP/1.0 404 Document not found$CRLF";
  print $c "Content-type: text/html$CRLF$CRLF";
  print $c <<END;
<HTML>
<HEAD><TITLE>404 Not Found</TITLE></HEAD>
<BODY><H1>Not Found</H1>
 <P>The requested document was not found on this server.</P>
</BODY>
</HTML>
END
}

sub docroot {
  $DOCUMENT_ROOT = shift if @_;
  return $DOCUMENT_ROOT;
}

1;

#!/usr/bin/perl
# server configuration variables

$ssl_server_key="ssl/myserver.key";
$ssl_server_cert="ssl/myserver.crt";
$log_level=4;
$ssl_port=8443;
$tcp_port=0;
$listeners=10;
$background=0;
$prefork=1;

{
package MyWebServer;

use HTTP::Server::Simple::CGI::PreFork;
our @ISA = qw(HTTP::Server::Simple::CGI::PreFork);


my %dispatch = (
    'hello.cgi' => \&resp_hello,
    # ... handle specific requests, instead of generics...
);

sub handle_request {
    my ($self, $cgi) = @_;

    my $method = $ENV{REQUEST_METHOD}; 
    my $path = $cgi->path_info();
    $path =~ s/^\///s;
    $path="index.html" if ( $path eq "" );
    
    my $handler = $dispatch{$path};

    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);
    } else {
        if ($method eq "GET") {
                send_file_response($path,$cgi);
        } else {
            do_404($cgi);
        }
    }
}

sub do_404 {
    my $cgi = shift;
    my $path = $cgi->path_info();
    $path =~ s/^\///s;
    print "HTTP/1.0 404 Not found\r\n";
    print $cgi->header,
    $cgi->start_html('Not found'),
    $cgi->h1('404 Not found'),
    $cgi->h2('Invalid request: ' . $path),
    $cgi->end_html;
}

sub print_content_type {
    my $_ = shift;

    if (m/.gif$/) {
        print "Content-Type: image/gif\r\n\r\n";
    } elsif ( (m/.jpg$/) || (m/.jpeg$/) ) {
        print "Content-Type: image/jpeg\r\n\r\n";
    } elsif (m/.html$/) {
        print "Content-Type: text/html\r\n\r\n";
    } else {
        print "Content-Type: text/plain\r\n\r\n";
    }
}

sub send_file_response {
    my ($path, $cgi) = @_;
    
    if ( -e $path ) {
        print "HTTP/1.0 200 OK\r\n";
        print_content_type($path);
        
        open(my $f, "<$path");
        while (<$f>) { print $_ };
        close($f);
    } else {
        do_404($cgi);
    }
}


sub resp_hello {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
    
    my $who = $cgi->param('name');
    
    print $cgi->header,
          $cgi->start_html("Hello"),
          $cgi->h1("Hello $who!"),
          $cgi->end_html;
}

} # end of package MyWebServer


sub start_ssl_only {
  my $place = shift;
  my $pid = MyWebServer->new("$ssl_port/ssl")->$place(
      ipv    		=> "*",
      log_level		=> $log_level,
      listen		=> $listeners,
      SSL_key_file	=> "$ssl_server_key", 
      SSL_cert_file	=> "$ssl_server_cert",
      prefork		=> $prefork,
  );
}

sub start_tcp_only {
  my $place = shift;
  my $pid = MyWebServer->new("$tcp_port/tcp")->$place(
      ipv    		=> "*",
      log_level		=> $log_level,
      listen		=> $listeners,
      prefork		=> $prefork,
  );
}

sub start_both {
  my $place = shift;
  my $pid = MyWebServer->new("$ssl_port/ssl")->$place(
      port		=> $tcp_port,
      proto		=> "tcp",
      ipv   		=> "*",
      log_level		=> $log_level,
      listen		=> $listeners,
      SSL_key_file	=> "$ssl_server_key", 
      SSL_cert_file	=> "$ssl_server_cert",
      prefork		=> $prefork,
    );
}

my $run="run"; # default to foreground ...
$run="background" if ($background);

if ( $ssl_port gt 0 ) {
    # Definitely start the SSL port
    if ( $tcp_port gt 0 ) {
      # Definitely also start the TCP port
      start_both($run);
    } else {
      # Start only SSL (from above)
      start_ssl_only($run);
    }
 } else {
    # No SSL port defined, so...
    if ( $tcp_port gt 0 ) {
      start_tcp_only($run);
    } else {
      print "No listeners! exiting...\n";
    }
}

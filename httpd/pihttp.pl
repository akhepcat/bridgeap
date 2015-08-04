#!/usr/bin/perl
# server configuration variables
$ssl_server_key="/etc/ssl/private/pitouch-nokey.pem";
$ssl_server_cert="/etc/ssl/certs/pitouch.pem";
$log_level=4;
$ssl_port=0;
$tcp_port=8080;
$listeners=1;
$background=0;
$prefork=0;
$dirindex=1;

{
package MyWebServer;

use parent qw(HTTP::Server::Simple::CGI::PreFork Net::Wireless::802_11::WPA::CLI);

our $dirindex;


my %dispatch = (
    'hello.cgi' => \&resp_hello,
    'stop.cgi' => \&stop_bridgeap,
    'reboot.cgi' => \&reboot_pi,
    'shutdown.cgi' => \&halt_pi,
    'scan.cgi' => \&cgi_wifi_scan,
    'cgi_connect_ap.cgi' => \&cgi_preconnect,
    'wpa_list_nets.cgi' => \&wpa_listnet,
    # ... handle specific requests, instead of generics...
);


sub handle_request {
    my ($self, $cgi) = @_;
    
    my $method = $ENV{REQUEST_METHOD}; 
    my $path = $cgi->path_info();
    $path =~ s/^\///s;
    
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
    my $mime = shift;

    if ($mime =~ m/.gif$/) {
        print "Content-Type: image/gif\r\n\r\n";
    } elsif ( ($mime =~ m/.jpg$/) || ($mime =~ m/.jpeg$/) ) {
        print "Content-Type: image/jpeg\r\n\r\n";
    } elsif ( $mime =~ m/.png$/ ) {
        print "Content-Type: image/png\r\n\r\n";
    } elsif ($mime =~ m/.html$/) {
        print "Content-Type: text/html\r\n\r\n";
    } else {
        print "Content-Type: text/plain\r\n\r\n";
    }
}

sub send_file_response {
    my ($path, $cgi) = @_;
    
    $path =~ s/sitestats/\/srv\/http\/sitestats/;
    $path = "index.html" if ( $path eq "" );
    $path = $path . "index.html" if ( $path =~ (m/\/$/) and ($dirindex > 0) );
    
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

sub wpa_listnet {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
    my $result;
    my $wpa = Net::Wireless::802_11::WPA::CLI->new();
    
    print $cgi->header,
          $cgi->start_html("Listing configured networks"),
          $cgi->h1("Listing configured networks");

    print "<br />\n";

    if( undef($wpa) ){
        print $cgi->h2("wpa_cli error(opening wpa_cli): " . $wpa->error . "<br />\n");
        print $wpa->errorString . "<br />\n";
    } else {
        my %networks = $wpa->list_networks();
        if( defined($wpa->error) ){
            print $cgi->h2("wpa_cli error(listing networks): " . $wpa->error . "<br />\n");
            print $wpa->errorString . "<br />\n";
        } else {
            print "<table>\n";
            print qq|<tr><th>id</th> <th>SSID</th> <th>BSSID</th> <th>Flags</th></tr>\n|;
            for my $key (keys(%networks)) {
                print qq|<tr><td>$key</td> <td>$network{$key}{"ssid"}</td> <td>$network{$key}{"bssid"}</td> <td>$network{$key}{"flags"}</td></tr>\n|;
            }
            print "</table><br />\n";
        }
    }
    print $cgi->end_html;
}

sub stop_bridgeap {
    my $cgi  = shift;   # CGI.pm object
    my $result;
    return if !ref $cgi;
    
    print $cgi->header,
          $cgi->start_html("Stopping BridgeAP"),
          $cgi->h1("Stopping BridgeAP");

    $result=qx|/usr/local/bin/bridgeap stop|;

    print "bridgeap reports: '$result'<br />\n";
    print $cgi->end_html;
}

sub reboot_pi {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
    
    print $cgi->header,
          $cgi->start_html("Reboot System"),
          $cgi->h1("Rebooting the system");

    $result=qx|shutdown -r now "Web reboot requested"|;

    print "shutdown reports: '$result'<br />\n";
    print $cgi->end_html;
}


sub halt_pi {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
    
    print $cgi->header,
          $cgi->start_html("Shutdown System"),
          $cgi->h1("Shutting down the system");

    $result=qx|shutdown -h -P now "Web shutdown requested"|;

    print "shutdown reports: '$result'<br />\n";
    print $cgi->end_html;
}

sub cgi_preconnect {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
    
    my $key = $cgi->param('enc');
    my $bssid = $cgi->param('bssid');
    
    print $cgi->header,
          $cgi->start_html("WiFi Preconnect"),
          $cgi->h1("WiFi Preconnect!");
    
    print "Preparing to connect to bssid: $bssid<br />\n";
    
    if ($key ne "yes") {
      print "No encryption key needed, stand-by for WiFi connection.<br />\n";
      $cgi->h2("connecting not implemented yet!");
    } else {
      print "Encryption key required:<br />\n";
      print $cgi->start_form( -method=>"POST", -action=>"/connect_wifi.cgi");
      print $cgi->password_field(-name=>'psk',  -value=>'Wifi Secret',  -size=>30,  -maxlength=>30);
      print $cgi->submit(-name=>'connect', -value=>'connect');
      print $cgi->end_form;
    }

    print $cgi->end_html;
}


sub cgi_wifi_scan {
  my $cgi = shift;
  return if !ref $cgi;
  
  my $matches=0;
  my $iface;

    print $cgi->header,
          $cgi->start_html("WiFi Scan"),
          $cgi->h1("Scanning the local wifi, please wait...");


  my $iwcmd = "/sbin/iwconfig 2>&1";

  open list, "$iwcmd |";
  while (<list>) {
     chomp;
    if (/^(\S+)\s+(IEEE)\s+(802.11)/) {
       $iface = $1;
       $matches ++;
    }
  }

  if ($matches != 1) {
    if ($matches < 1) {
      print "Can't find any wireless interfaces.\n";
    } else {
      print "Too many wireless interfaces for auto-scan.\n";
    }
  } else {

      my $apmac = qx|iwgetid -ar|;
      chomp($apmac);

      print "<!-- found current connection of '$apmac' -->\n";
      
      my $stylel=qq|style="text-align:left;"|;
      my $stylec=qq|style="text-align:center;"|;
      my $styler=qq|style="text-align:right;"|;
      print "<table>\n";
      print "<tr><th $stylel>ESSID</th> <th $stylec>BSSID</th> <th $stylel>Mode</th> <th $styler>Channel</th> <th $styler>Signal Level</th> <th $styler>Encryption</th></tr>\n";
      $iwlist = "/sbin/iwlist $iface scanning";

      open scan, "$iwlist |";
      while (<scan>) {
      if (/^\s+Cell (\S+) - Address: (\S+)/) {
        $CELL=$1;
        $ADDRESS=$2;
        # print "$1 $2";
        $INLOOP=1;
      }
      next if ( $INLOOP < 1 );
    
      if (/^\s+ESSID:"(\S+)"/) {
        $ESSID=$1;
      } elsif (/^\s+Frequency:\S+ \S+ \(Channel (\S+)\)/) {
        $CHAN=$1;
      } elsif (/^\s+Quality=\S+\s+Signal level=(\S+).*/) {
        $SIGNAL=$1;
      } elsif (/^\s+Encryption key:(\S+)/) {
        $ENCRYPTION=$1;
      } elsif (/^\s+Mode:(\S+)/) {
       $PRINT=1;
       $MODE=$1;
      }
    
      if ($INLOOP > 0 and $PRINT >0) {
       $PRINT=0;
       $INLOOP=0;
       
       if (lc($ADDRESS) eq lc($apmac)) {
         $strong=qq|color: green;font-weight:bold|;
         $linkb=""; $linke="";
       } else {
         $strong=""; $enc="";
         $enc = "&enc=yes" if ($ENCRYPTION eq "on");
         
         $linkb=qq|<a href="/cgi_connect_ap.cgi?bssid=$ADDRESS$enc">|;
         $linke=qq|</a>|;
       }
       $stylel=qq|style="text-align:left; $strong"|;
       $stylec=qq|style="text-align:center; $strong"|;
       $styler=qq|style="text-align:right; $strong"|;

       print "<tr><td $stylel >$linkb$ESSID$linke</td> <td $stylec >$ADDRESS</td> <td $stylel >$MODE</td> <td $styler >$CHAN</td> <td $styler >$SIGNAL</td> <td $styler >$ENCRYPTION</td></tr>\n";
       
      }
    }
    close scan;

    print "</table>\n";
    print $cgi->end_html;

    }
  }

} # end of package MyWebServer

########################################################################

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

# import the 'global' config option into the package
$MyWebServer::dirindex = $dirindex;

my $run="run"; # default to foreground ...

$run="background" if ($background);

if ( $ssl_port > 0 ) {
    # Definitely start the SSL port
    if ( $tcp_port > 0 ) {
      # Definitely also start the TCP port
      start_both($run);
    } else {
      # Start only SSL (from above)
      start_ssl_only($run);
    }
 } else {
    # No SSL port defined, so...
    if ( $tcp_port > 0 ) {
      start_tcp_only($run);
    } else {
      print(STDERR "No listeners! exiting...\n");
    }
}

exit;

#########################################################################

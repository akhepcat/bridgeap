# bridgeap
Automagically bridge any live interface to any idle interface using NATS, DHCP, and HostAP where applicable

Use case:
  * You're in a hotel that has wired ethernet, but no WiFi
  * You're in a hotel that has wifi, a captive portal, and device limits
  * You're in a hotel and want to use your chromecast
  * You just want to share your network connection with your friends
  * You want to connect via VPN* and then share that over WiFi
  
  The sky is the limit!

This script was originally written for debian/ubuntu platforms, but should be portable to anything.

If you are missing any prerequisite packages, you'll be informed at script startup.

FAQ on the wiki: https://github.com/akhepcat/bridgeap/wiki

Raspberry Pi users:
  Some usb wifi adapters may require the addition of "max_usb_current=1"  in /boot/config.txt
in order to prevent hotplug->reboot problems.

\*VPN Users:
  The script should auto-detect your VPN tunnel interface, but you'll need to make sure that you're
connected prior to launching bridgeap.

***

# IPv6


IPv6 support has been identified, however it is mostly beyond the scope of bridgeap.  That being said,
if aiccu is used to provide IPv6 subnets, it should be -possible- to add support for automatically
starting/restarting aiccu, fetching the subnet information, passing that into the radvd configuration
and starting that daemon.   If you're interested in this, file a feature request issue in the tracker.  

*update*  aiccu does not support passing the routed netblock information between server and client,
mostly because the server doesn't have a method to support it.  I've opened a ticket with sixxs for that.
So, any work is effectively on hold here.

*update 2* I've added some initial support for IPv6 subnet routing based on static configuration,
as well as using aiccu as an optional provider of the IPv6 route.  Caveat emptor.

***

# V2 

-- what's before alpha state?

Early attempts at creating a perl-based web-server for monitoring/controlling the bridgeap daemon
as well as the upstream WiFi connectivity.  Nobody likes ssh'ing and editing /etc/wpa_supplicant.

You'll need to install one perl module (and it's automatic prerequisites) by running this:

\# sudo perl -MCPAN -e 'install HTTP::Server::Simple::CGI::PreFork'


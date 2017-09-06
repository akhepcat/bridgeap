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


I've added some initial support for IPv6 subnet routing based on static configuration.  Caveat emptor.
Since SIXXS is no longer providing an aiccu tunnel endpoint, that option no longer works.

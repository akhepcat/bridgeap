# bridgeap
Automagically bridge any live interface to any idle interface using NATS, DHCP, and HostAP where applicable

Use case:
  * You're in a hotel that has wired ethernet, but no WiFi
  * You're in a hotel that has wifi, a captive portal, and device limits
  * You're in a hotel and want to use your chromecast
  * You just want to share your network connection with your friends
  
  The sky is the limit!


This script was originally written for debian/ubuntu platforms, but should be portable to anything.

If you are missing any prerequisite packages, you'll be informed at script startup.

FAQ on the wiki: https://github.com/akhepcat/bridgeap/wiki

some usb wifi adapters may require the addition of "max_usb_current=1"  in /boot/config.txt  in order to
prevent hotplug->reboot problems.


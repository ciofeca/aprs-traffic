# APRS packet logging

Idea:
- collect APRS traffic, generate statistics and prepare an HTML page to publish.
- have a look: http://aprs-traffic.blogspot.com

Hardware:
- an APRS-capable receiver (I use a Kenwood TH-D7E that sends packets on its RS232 port)
- a Perl/Ruby/shell-enabled server (my Linux box)

Implementation:
- *start-aprs-service.cron* to start the aprs service script at boot
- *run-aprs-service.sh* to start/restart the Perl script
- *packet-aprs-ciapa.pl* decodes APRS packets, saves hourly data files
- *generate-aprs-page.rb* parses available data files, builds page, sends the email
- *email.rb* emails an HTML page to an "email to blog" service

Data files (in the *in/* directory):
- text files, one field per page (fieldname, tab, fieldvalue)
- first field is always *symbolcode*
- last field is always *aprs_packet* with "ok"/"error" and Unix timestamp


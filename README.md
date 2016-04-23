# APRS packet logging

Idea:
- collect APRS traffic, generate 24h statistics, prepare an HTML page, publish it
- have a look: https://aprs-traffic.blogspot.com

Hardware: a 24/365 Linux box and an APRS radio with a TNC:
- my old rig: a Kenwood TH-D7 radio (includes a TNC2-compatible with an RS232 port)
- my current rig: a Yaesu FT-23R radio and a MicroModem MDMRC24B (http://unsigned.io)

Software:
* fetch APRS data packets in KISS (binary) or TNC2 (ascii) format
* decode packet attributes and save them in hourly log-files
* every day: build a summary HTML page from collected log-files

Implementation:
- *start-aprs-service.cron* defines boot autostart aprs service and daily summary page generation
- *run-aprs-service.sh* to start/restart the Perl script
- *packet-aprs-kiss.pl* collects and decodes APRS packets, saves hourly data files (KISS mode)
- *packet-aprs-ciapa.pl* collects and decodes APRS packets, saves hourly data files (TNC2 mode)
- *test-aprs-kiss.pl* test Perl library packet decoding
- *generate-aprs-page.rb* parses available data files, builds page, sends the email
- *email.rb* emails an HTML page to an "email to blog" service

Data files (in the *in/* directory):
- text files, one field per line (fieldname, tab, fieldvalue)
- first field is always *symbolcode*
- last field is always *aprs_packet* with *ok* or *error* followed by Unix timestamp


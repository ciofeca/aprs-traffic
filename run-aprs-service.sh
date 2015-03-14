#!/bin/bash

# serial port where we will listen for incoming packets
PORT=/dev/serial/by-id/usb-1a86_USB2.0-Ser_-if00-port0

# my Kenwood TH-D7E radio uses 9600 baud
stty -F $PORT raw ispeed 9600 ospeed 9600 < $PORT

LOGFILE=/tmp/packet-aprs-ciapa.log

while true
do
  ./packet-aprs-ciapa.pl >> $LOGFILE 2>&1
  date >> $LOGFILE
  sleep 1
done

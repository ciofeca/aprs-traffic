#!/bin/bash

# serial port where we will listen for incoming packets
# (if you have more than a ttyUSB* then it's safer to use the /dev/serial/by-id/* equivalent)
PORT=/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AI035VW2-if00-port0

# my Kenwood TH-D7E radio uses 9600 baud, need to explicitly set up speed using stty:
#stty -F $PORT raw ispeed 9600 ospeed 9600 < $PORT

LOGFILE=/tmp/packet-aprs-ciapa.log

cd in/
while true
do
  ../packet-aprs-kiss.pl >> $LOGFILE 2>&1
  date >> $LOGFILE
  sleep 1
done

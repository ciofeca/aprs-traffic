#!/usr/bin/perl

# requires CPAN libraries:
#   cpan install Device::TNC::KISS Ham::APRS::FAP

use Ham::APRS::FAP qw(parseaprs kiss_to_tnc2);
use Device::TNC::KISS;

my %config = (
  'port' => '/dev/ttyUSB2',
  'baudrate' => 9600,
  'warn_malformed_kiss' => 0,
  'raw_log' => '/dev/null'
);

my $micromodem = new Device::TNC::KISS(%config);

while(my $kisspkt = $micromodem->read_kiss_frame())
{
  $kisspkt =~ s/^\xc0//;
  $kisspkt =~ s/\xc0$//;
  $pkt = kiss_to_tnc2($kisspkt);
  %data = ();
  $aprs = parseaprs($pkt, \%data);
  if ( $aprs == 1 )
  {
    print "aprs: ok\n";
    while ( ($key, $value) = each(%data) )
    {
      if($key eq 'capabilities' or $key eq 'wx' or $key eq 'digipeaters')
      {
        if($key eq 'digipeaters')
        {
          while(my($kk,$vv) = each $value)
          {
            while(my($kkk,$vvv) = each $vv)
            {
              print "digi_$kk" . "_$kkk: $vvv\n";
            }
          }
        }
        else
        {
          while(my($kk,$vv) = each $value)
          {
            print "$key" . "_$kk: $vv\n";
          }
        }
      }
      else
      {
        print "$key: $value\n";
      }
    }
  }
  else
  {
    print "aprs: error\n";
    print "resultcode: $data{resultcode}\n";
    print "resultmsg: $data{resultmsg}\n";
  }
  print "\n";
}

# ---

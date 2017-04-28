#!/usr/bin/env perl

# requires CPAN libraries:
#   cpan install Date::Calc Device::TNC::KISS Ham::APRS::FAP

use Ham::APRS::FAP qw(parseaprs distance kiss_to_tnc2);
use Device::TNC::KISS;
use POSIX;

my %config = (
  'port'     => '/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AI035VW2-if00-port0',
  'baudrate' => 9600,
  'warn_malformed_kiss' => 0,
  'raw_log'  => '/dev/null'
);

# home station position (for distance calculation)
my $latdist=40.6975638;
my $londist=14.4621494;

my $tnc_kiss = new Device::TNC::KISS(%config);
while(my $kisspkt = $tnc_kiss->read_kiss_frame())
{
  $kisspkt =~ s/^\xc0//;
  $kisspkt =~ s/\xc0$//;
  my $pkt = kiss_to_tnc2($kisspkt);
  my %dat = ();
  my $t = time;
  open(OUT, strftime('>>%Y%m%d-%H.aprs', localtime));
  my $x = parseaprs($pkt.chomp, \%dat);
  if($x != 1)
  {
    if($pkt != "")
    {
      print OUT "resultcode\t$dat{resultcode}\n";
      print OUT "resultmsg\t$dat{resultmsg}\n";
      print OUT "aprs_packet\terror\t$t\n\n";
    }
  }
  else
  {
    while(my($k,$v) = each %dat)
    {
      # forget body, origpacket, header - they may have invalid characters
      if($k ne 'body' and $k ne 'origpacket' and $k ne 'header')
      {
        # check arrays
        if($k eq 'capabilities' or $k eq 'wx' or $k eq 'digipeaters')
        {
          # digipeaters require special treatment
          if($k eq 'digipeaters')
          {
            while(my($kk,$vv) = each $v)
            {
              while(my($kkk,$vvv) = each $vv)
              {
                print OUT "digi_$kk" . "_$kkk\t$vvv\n";
              }
            }
          }
          else
          {
            # wx and capabilities
            while(my($kk,$vv) = each $v)
            {
              print OUT "$k" . "_$kk\t$vv\n";
            }
          }
        }
        else
        {
          if($k eq 'longitude')
          {
            my $dist = distance($latdist, $londist, $dat{latitude}, $dat{longitude});
            print OUT "distance\t$dist\n";
          }
          # fallback for extra fields:
          print OUT "$k\t$v\n";
        }
      }
    }

    print OUT "aprs_packet\tok\t$t\n\n";
  }

  close(OUT);
}


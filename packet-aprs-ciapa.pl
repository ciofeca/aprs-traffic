#!/usr/bin/env perl

# requires Ham::APRS::FAP and POSIX

# serial port
my $ser = '/dev/serial/by-id/usb-1a86_USB2.0-Ser_-if00-port0';

# home station position (for distance calculation)
my $latdist=40.6975638;
my $londist=14.4621494;

use POSIX;
use Ham::APRS::FAP qw(parseaprs distance);

open my $info,$ser or die "cannot open serial port $ser: $!";
while(my $pkt=<$info>)
{
  my %dat;
  my $t = time;
  open(OUT, strftime('>>%Y%m%d-%H.aprs', localtime));
  my $x = parseaprs($pkt.chomp, \%dat, 'isax25' => 0);
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


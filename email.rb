#!/usr/bin/env ruby

FROM='some gmail account <i_created_this_only_to_send_a_mail@gmail.com>'
SMTP='smtp.gmail.com'
PORT=587
USER='i_created_this_only_to_send_a_mail'
HELO='gmail.com'
PASS='orzobimbepimpumpam'
TLSM=true
ADDR='my.blog.secret.mailtoblog.address@blogger.com'

require 'net/smtp'
require 'net/smtp-tls'  # required for gmail smtp; not available on Ubuntu; must be placed in /usr/lib/ruby/.../net/

if ARGV.size != 1
  STDERR.puts "usage: #{$0} 'subject' < text"
  exit 1
end

to = ADDR
tim = Time.now.to_f
subj = ARGV.first
pigre = 3.1415926536897932354626
filn, filc, film, attachm = nil, nil, nil, ''
ext = ""

msg = "From: #{FROM}
To: #{to}
Subject: #{subj}
Date: #{Time.now.localtime}
Message-Id: <#{$$}#{tim*pigre}.#{USER}>
X-Mailer: RubyPersonalMailer by AlfonSoftWare International 2009-2013
X-Click-Here: http://aprs-traffic.blogspot.com
Content-Type: multipart/mixed; boundary=A#{tim}

#{attachm}
--A#{tim}
Content-Transfer-Encoding: quoted-printable
Content-Type: text/html; charset=UTF-8

#{STDIN.readlines.join}

--A#{tim}--
"

# se si lamenta (warning regex utf8) allora:
# require 'cgi'
# CGI.escapeHTML(STDIN.readlines.join)


if TLSM
  #Net::SMTP.starttls(OpenSSL::SSL::VERIFY_NONE)  
  Net::SMTP.start(SMTP, PORT, HELO, USER, PASS, :login) do |smtp|
    smtp.send_message msg, USER, to
  end
else
  Net::SMTP.start(SMTP, PORT, HELO, USER, PASS, :plain) do |smtp|
    smtp.sendmail msg, FROM, to
  end
end

# ---

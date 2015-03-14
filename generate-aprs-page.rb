#!/usr/bin/env ruby

EMAILPROG='./email.rb'

# load symbol table (two letter symbol => static image URI)
load "#{$0}.symboltable"

# work directory
Dir.chdir "#{File.dirname $0}/in"

# show an extra comment if a single station generates packets more often than one every MAXSEC seconds
MAXSEC=999.999

# directory: where processed files go
PROCESSED = "../processed"

# files: temporary shell for debugging, log file, HTML page
TMPSHELL  = "/tmp/last-aprs.sh"
TMPLOG    = "/tmp/last-aprs.txt"
TMPFILE   = ARGV.first || "/tmp/last-aprs.html"

# invalid callsigns to be marked in red
INVALIDCS = [ 'ARIRE', 'CALL', 'NOCALL' ]

# wipe these invalid start/stop values
SLIST = [ ']=', ']}', ']0', '"}', '\=', '"(' ]

# wipe out these strings at the end of the packet
PLIST = [ ' }', ' {' ]

# do not show those stooopid UI-View version numbers
GLIST = [ /\{uiv32\}/i, /\{uiv32n\}/i, /UI-View V2.39/i, /UI-View32 V2.03/i, /UIDIGI 1.9b3/i ]


def perc xmed,xtop,xmsg
  "#{(xmed*1000.0/xtop).floor/10.0}% #{xmsg}"
end

def gradi n, up, down
  if n<0
    n = -n
    up = down
  end

  g = n.floor
  r = (n-g)*60.0
  m = r.floor
  s = ((r-m)*600.0).floor/10.0

  "#{g}&ordm;#{m}'#{s}\"#{up}"
end

def symclean str
  return ''  if str=='' || str==nil
  SLIST.each do |s|
    s1,s2 = s[0..0], s[-1..-1]
    if str[0..0]==s[0..0] && str[-1..-1]==s[-1..-1]
      return str[1..-2]
    end
  end
  str.chomp('0')
end

def pubbliclean str
  return ''  if str=='' || str==nil
  GLIST.each do |s|
    str = "#{$`}#{$'}"  if str =~ s
  end
  PLIST.each do |s|
    e = str[-(s.size)..-1]
    next unless e
    next unless e.casecmp(s)==0
    return str.chomp(e)
  end
  str
end

# --- oggi
oggi = Time.now.strftime("%Y%m%d-%H")
files = Dir["20*.aprs"].delete_if { |s| s >= oggi }.sort
if files.size==0
  puts "!-- there are no files before current day"
  exit 0
end

# --- main
info = {}
upto,from = nil, nil
cnt, cntloc, cntwea, packets, errs = 0,0,0,0,0
pktype = {}
pktype.default = 0
tab = {}
tab.default = [nil]

riga = ''
files.each do |filename|
  File.open(filename).each_line do |linea|
    begin
      riga = linea.encode!('iso8859-1', 'UTF-8', :invalid => :replace).chomp.strip
    rescue
      riga = ''
    end
    next if riga==''

    # group all fields until the last one
    campi = riga.split(/\t/)
    t = campi.delete_at(0)
    r = campi.join("\t")
    if t != 'aprs_packet'
      info[t] = r
      next
    end

    # error check
    if campi.first != 'ok' || info['srccallsign']==nil
      #puts "!--error: pkt #{packets+1} #{info['srccallsign']} #{info['resultcode']} #{info['resultmsg']}"
      errs += 1
      info = {}
      next
    end
    pktype[info['type']] += 1

    # now we have all fields of a single packet; let's update the global counters:
    packets += 1
    cnt += 1
    upto = campi.last           # last timestamp of this session
    from = upto  unless from    # first timestamp di this session

    # update the packet, index by source call-sign:
    cs = info['srccallsign'].split('-').first
    firstseen, lastseen, icon, lastpos, lastdistance, pkts, dst, obj, item, msg, wea, notes = tab[cs]
    ts = Time.at upto.to_i

    # firstseen, lastseen, icon, lastpos, lastdistance, pkts, notes
    firstseen = ts  unless firstseen
    lastseen = ts

    # if both sym1/sym2 available, add the <img> tag for its icon
    sym, sym1, sym2 = '', info['symboltable'], info['symbolcode']
    sym = SYMBOLTABLE[ sym1+sym2 ]  if sym1 && sym2 
    sym = "<img src=\"#{sym}\">"  if sym!=''
    icon = sym  unless sym==''

    # coordinates: only if both available
    lat, lon = info['latitude'], info['longitude']
    if lat && lon && (lat!='0' && lon!='0')
      cntloc += 1
      lastpos = "#{gradi(lat.to_f,'N','S')},&nbsp;#{gradi(lon.to_f,'E','W')}"
      lastdistance = info['distance'].to_f  if info['distance']
    end

    # packet counter
    pkts = 0  unless pkts
    pkts += 1

    # extra info (currently not used)
    dst = info['dstcallsign'] || dst
    obj = info['objectname'] || obj
    itm = info['itemname'] || itm
    msg = info['messaging'] || msg
    obj = obj.strip  if obj

    # weather data
    wx = %w(temp pressure humidity rain_midnight wind_speed luminosity snow_24h).collect { |i| info["wx_#{i}"] }
    wea = '' #   1        2        3             4          5          6
    wea += "#{wx.first}&ordm;C "  if wx.first
    wea += "#{wx[1]}mbar "        if wx[1] && wx[1].to_f > 800
    wea += "#{wx[2]}%hr "         if wx[2] && wx[2].to_f != 0
    wea += "#{wx[3]}mm "          if wx[3] && wx[3].to_i != 0
    wea += "#{wx[4]}m/s "         if wx[4] && wx[4].to_f != 0
    wea += "#{wx[5]}w/m&sup2; "   if wx[5] && wx[5].to_f > 0
    wea += "#{wx[6]}mm-snow"      if wx[6] && wx[6].to_i != 0
    wea.strip!
    cntwea += 1  if wx.compact.size>0

    # cleaning comments
    txt = pubbliclean(symclean "#{info['status']} #{info['comment']}".strip).strip
    notes = txt  unless txt==''

    # updating internal database  1     2        3             4     5    6    7    8    9   10     11
    tab[cs] = [ firstseen, lastseen, icon, lastpos, lastdistance, pkts, dst, obj, itm, msg, wea, notes ]
    #puts "#{cs}:  #{tab[cs][-1].inspect} -- dst[#{dst}] obj{#{obj}} itm(#{itm}) msg<#{msg}> "
    info = {}
  end
  puts "!--ok: #{filename} (#{cnt})"
  cnt = 0
end


ogni = ((upto.to_i-from.to_i)*10.0/packets).floor/10.0
timediff = upto.to_i-from.to_i
from = Time.at(from.to_i).strftime('%a %-d %H:%M:%S')
titl = Time.at(upto.to_i).strftime('%Y-%m-%d')
upto = Time.at(upto.to_i).strftime('%a %-d %b %H:%M:%S')
ore = (timediff/3600).floor
case
  when ore==0
    ore = ''
  when ore==1
    ore = 'one hour, '
  when ore>1
    ore = "#{ore} hrs, "
end
timediff = Time.at(timediff%3600)
tdiff = timediff.strftime("#{ore}%-M min %-S sec")
#puts "from[#{from}] -- upto[#{upto}] -- total[#{timediff.to_i}] #{timediff}"

# don't be exact if distance is less than 100 kilometers
nonlocal, maxkm, minkm = 0,0,999999
tab.each do |k,v|
  dist = v[4] || -1
  nonlocal += 1  if dist>=100
  maxkm = dist   if dist>maxkm
  minkm = dist   if dist>=0 && dist<minkm
end
minkm = 0  if minkm>40576
maxkm = (maxkm*10.0).floor/10.0
minkm = (minkm*10.0).floor/10.0

puts "statistics from #{from} to #{upto} (#{tdiff})"
puts "#{packets} total packets (one every #{ogni} seconds)"
#puts "\t"+perc(cntloc, packets, "containing locations (#{cntloc}/#{packets})")
#puts "\t"+perc(cntwea, packets, "containing weather data (#{cntwea}/#{packets})")
#puts "packet summary:"
#pktype.sort_by { |k,v| v }.reverse.each { |k,v| puts "\t"+perc(v, packets, k) }
#puts "#{tab.size} stations, "+perc(nonlocal,tab.size,"non local (more than 100km); max distance #{maxkm}; min distance #{minkm}")
#tab.sort_by { |k,v| v[5] }.reverse.each do |k,v|
#  tsec, sec, tot = '', (v[1].to_i-v[0].to_i), v[5].to_i
#  if sec>0 && tot>0
#    tot = (sec*10.0/tot).floor/10.0
#    tsec = "1 / #{tot}sec"   if tot<1200
#  end
#  puts "\t#{k}\t#{v[5]}\t#{tsec}\t"+"#{v[-2]} #{v[-1]}".strip
#end

fp = File.open(TMPFILE, "w")

fp.print "<p>Statistics spanning #{tdiff}, up to #{upto} local time (GMT+1):"
fp.print "<ul><li><b>#{tab.size}</b> different stations</li>"
fp.print "<li><i>#{perc(nonlocal,tab.size, 'non-local stations')}</i> (more than 100 km from here)"
fp.print "<br><small><i>(max distance: #{maxkm} km; nearest: #{minkm} km)</i></small></li>"
fp.print "<li>#{packets} total APRS packets (one every #{ogni} seconds):"
fp.print "<br>#{'&nbsp'*4}#{perc(cntloc, packets, 'reporting location')}"
fp.print "<br>#{'&nbsp'*4}#{perc(cntwea, packets, 'reporting weather data')}</li>"
fp.print "<li>packet identification summary:<small>"
pktype.sort_by { |k,v| v }.reverse.each { |k,v| fp.print "<br>#{'&nbsp'*8}<i>"+perc(v, packets, "</i>#{k}") }

# uncomment if you have the "tw" script to tweet on twitter:
#system "/home/ciofeca/Desktop/tw #{tab.size} stations, #{packets} packets / every #{ogni} seconds, #{cntloc} locations, #{cntwea} weather data"

fp.print '</li></ul></small><p><center>'
fp.print '<table cellspacing="3" border="1" cellpadding="1" align="center" summary="APRS data">'
fp.print '<tr><td><i>last seen</i></td><td><i>station</i></td><td><i>position</i></td>'
fp.print '<td><i>APRS packets</i></td><td><i>notes</i></td></tr>'

# key for sortby vv[x]:       1     2        3             4     5    6    7    8    9   10     11
#         [ firstseen, lastseen, icon, lastpos, lastdistance, pkts, dst, obj, itm, msg, wea, notes ]
# sort_by vv[5] reverse: by bigger number of packets received from a single station
# sort_by vv[1] reverse: by timestamp of last packet seen from a single station
tab.sort_by { |kk,vv| vv[1] }.reverse.each do |k,v|
  firstseen, lastseen, icon, lastpos, lastdistance, pkts, dst, obj, item, msg, wea, notes = v

  fp.print "<tr>"
  fp.print "<td><tt>#{lastseen.strftime '%Y-%m-%d<br>&nbsp;%H:%M:%S'}</tt></td>"

  fp.print "<td><b>#{icon} #{k}</b>"
  if INVALIDCS.include?(k)
    fp.print '<br><span style="background:red"><i><small>(invalid callsign)</small></i></span>'
  end
  fp.print "</td>"

  fp.print "<td>#{lastpos}"
  if lastdistance && lastdistance>100
    fp.print "<br><small><i>("
    case
      when lastdistance>20000
        fp.print "wow: 20000+ km from here"
      when lastdistance>18000
        fp.print "wow: 18000+ km from here"
      when lastdistance>16000
        fp.print "wow: 16000+ km from here"
      when lastdistance>14000
        fp.print "wow: 14000+ km from here"
      when lastdistance>12000
        fp.print "wow: 12000+ km from here"
      when lastdistance>10000
        fp.print "wow: 10000+ km from here"
      when lastdistance>9000
        fp.print "wow: 9000+ km from here"
      when lastdistance>8000
        fp.print "wow: 8000+ km from here!"
      when lastdistance>7000
        fp.print "wow: 7000+ km from here!"
      when lastdistance>6000
        fp.print "6000+ km from here!!!"
      when lastdistance>5000
        fp.print "5000+ km from here!!!"
      when lastdistance>4000
        fp.print "4000+ km from here!!!"
      when lastdistance>3500
        fp.print "3500+ km from here!!!"
      when lastdistance>3000
        fp.print "3000+ km from here!!"
      when lastdistance>2500
        fp.print "2500+ km from here!!"
      when lastdistance>2000
        fp.print "2000+ km from here!!"
      when lastdistance>1500
        fp.print "1500+ km from here!!"
      when lastdistance>1000
        fp.print "1000+ km from here!"
      when lastdistance>750
        fp.print "750+ km from here!"
      when lastdistance>500
        fp.print "500+ km from here!"
      when lastdistance>350
        fp.print "350+ km from here"
      when lastdistance>200
        fp.print "200+ km from here"
      when lastdistance>100
        fp.print "100+ km from here"
    end
    fp.print ")</i></small>"
  end
  fp.print "</td>"

  fp.print "<td>#{'&nbsp;'*2}#{pkts}"
  sec = lastseen.to_i-firstseen.to_i
  if sec>0 && pkts>4
    sec = (sec*10.0/pkts).floor/10.0
    fp.print "<br><i><small>(every #{sec} sec)</small></i>"  if sec<MAXSEC
  end
  fp.print "</td>"

  fp.print "<td>#{notes}"
  fp.print "<br><small>weather data: #{wea}</small>"  if "#{wea}"!=''
  #fp.print "<br><small>message: #{msg}</small>"       if "#{msg}"!=''
  fp.print "</td>"
  fp.print "</tr>"
end

upti = File.open("/proc/uptime").gets.split.first.to_i
days = upti/86400
upti = upti%86400
hrs  = upti/3600
upti = upti%3600
mins = upti/60

fp.print "</table></center><p><small>System uptime: "
case
  when days==0
    fp.print
  when days==1
    fp.print "one day"
  when days>=2 && days<=12
    fp.print "#{%w(two three four five six seven eight nine ten eleven twelve)[days-2]} days"
  else
    fp.print "#{days} days"
end

fp.print ", " if days>0 && (hrs>0 || mins>0)
fp.print "one hour"      if hrs==1
fp.print "#{hrs} hours"  if hrs>1
fp.print ", " if hrs>0
fp.print "one minute"    if mins==1
fp.print "#{mins} minutes"
fp.puts
fp.close

fp = File.open(TMPSHELL, "w")
cmd = "mv #{files.join ' '} #{PROCESSED}"
puts cmd
fp.puts cmd
system cmd  if ARGV.first

cmd = "#{EMAILPROG} 'APRS data: #{titl}' <#{TMPFILE} >>#{TMPLOG}"
puts cmd
fp.puts cmd
system cmd  if ARGV.first

puts "!--ok: #{Time.now}"

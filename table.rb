#!/usr/bin/ruby -W1
# coding: utf-8
require 'sqlite3'
require 'active_support'
require 'active_support/core_ext'
require 'erb'
#require 'gnuplot'
require_relative './config.rb'

def printweek (w)
    output = ""
    db = SQLite3::Database.new(DB)
    teams = db.execute("SELECT teams.teamid, points, pcts, teamname  FROM points,teams WHERE points.teamid=teams.teamid AND week=#{w} ORDER BY points DESC")
    output +=   "<center>\n"
    output +=   "    <br />\n"
    p "printweek: #{w}; #{Date.today.cweek}; #{Date.today.wday}; #{DOW}\n"
    if w==Date.today.cweek or (w==Date.today.cweek-1 and Date.today.wday.between?(1, DOW-1))
        output +=   "    <h1>Предварительные результаты #{w} недели</h1>\n"
    else
        output +=   "    <h1>Результаты #{w} недели</h1>\n"
    end
    output +=   "    <!--a href=\"teams#{w}.html\">Подробнее</a-->\n"
    output +=   "    <br />\n"
    output +=   "</center>\n"
    output +=   "<div class=\"datagrid\"><table>\n"
    output +=   "   <thead><tr><th>Команда</th><th>Выполнено (%)</th><th>Очки</th><th>Сумма</th></tr></thead>\n"
    output += "<tbody>\n\n"
    odd = true
    teams.each do |t|
        p t
        sum = db.execute("SELECT SUM(points) FROM points WHERE teamid=#{t[0]} AND week<=#{w}")[0]
        if odd
            output += "  <tr><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>\n"
        else
            output += "  <tr class=\"alt\"><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>\n"
        end
        odd = !odd
    end
    output +=   "   </tbody>\n"
    output +=   "</table>\n"
    output +=   "</div>\n"
    return output
end


$stdout.sync = true
now = Time.now.getutc
dayno = now.yday
if now < PROLOG.begin or now > (CHAMP.end + 2.days)
    puts "#{now}: Not yet time..."
    exit
end

week = now.to_date.cweek.to_i

prolog = ""
champ = ""
cup = ""


index_erb = ERB.new(File.read('index.html.erb'))
rules_erb = ERB.new(File.read('rules.html.erb'))
teams_erb = ERB.new(File.read('teams.html.erb'))
user_erb = ERB.new(File.read('u.html.erb'))
users_erb = ERB.new(File.read('users.html.erb'))
users2_erb = ERB.new(File.read('users2.html.erb'))
users3_erb = ERB.new(File.read('users3.html.erb'))
users4_erb = ERB.new(File.read('users4.html.erb'))
statistics_erb = ERB.new(File.read('statistics.html.erb'))

db = SQLite3::Database.new(DB)

### Process index.html
if now > PROLOG.begin #and now < 7.days.after(CLOSEPROLOG)
    prolog += "<center>\n"
    prolog += "<h1>Пролог</h1>\n"
    prolog += "</center>\n"
    prolog += "<div class=\"datagrid\">\n"
    prolog += "<table>\n"
    prolog += "<thead><tr><th>Имя</th><th>Команда</th><th>Объемы 2019 (км/нед)</th><th>Результат (км)</th></tr></thead>\n"
    prolog += "<tbody>\n"
    
    teams = db.execute("SELECT * FROM teams")
    
    odd = true
    runners = db.execute("SELECT runnerid,runnername,7*goal/365,teamid FROM runners")
    runners.each do |r|
        r << db.execute("SELECT COALESCE(SUM(distance),0) AS dist FROM log WHERE runnerid=#{r[0]} AND date>'#{PROLOG.begin.iso8601}' AND date<'#{PROLOG.end.iso8601}'")[0][0]
    end
    runners.sort! { |x,y| y[4] <=> x[4] }
    p runners
    runners.each do |r|
#        if now > CLOSEPROLOG
#            points = case runners.index(r)
#                     when 0 then 20
#                     when 1 then 10
#                     when 2 then 5
#                     else 0
#                     end
#        else
#            points = 0
#        end
        if odd then
            prolog += "<tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
        else
            prolog += "<tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
        end
        odd = !odd
    end
    
    prolog += "</tbody>\n"
    prolog += "</table></div>\n"
end

if now > CHAMP.begin
    w = Date.today.cweek
    p w
    if Date.today.wday.between?(1, DOW-1)
        teams = db.execute("SELECT teams.teamid, teamname, COALESCE(SUM(points),0) AS p FROM points, teams WHERE points.teamid=teams.teamid AND week<#{w-1} GROUP BY teams.teamid ORDER BY p DESC")
    else
        teams = db.execute("SELECT teams.teamid, teamname, COALESCE(SUM(points),0) AS p FROM points, teams WHERE points.teamid=teams.teamid AND week<#{w} GROUP BY teams.teamid ORDER BY p DESC")
    end
    champ +=   "<center>\n"
    champ +=   "    <br />\n"
    champ +=   "    <h1>Текущее положение команд</h1>\n"
    champ +=   "    <br />\n"
    champ +=   "</center>\n"
    champ +=   "<div class=\"datagrid\"><table>\n"
    champ +=   "   <thead><tr><th>Команда</th><th>Очки</th></tr></thead>\n"
    champ +=   "    <tbody>\n"
    odd = true
    teams.each do |t|
        if odd
            champ += "  <tr><td>#{t[1]}</td><td>#{t[2]}</td></tr>\n"
        else
            champ += "  <tr class=\"alt\"><td>#{t[1]}</td><td>#{t[2]}</td></tr>\n"
        end
        odd = !odd
    end
    champ +=   "   </tbody>\n"
    champ +=   "</table>\n"
    champ +=   "</div>\n"
    champ +=   "<br />\n"
    champ += printweek w
    champ +=   "<br />\n"
    [*CHAMP.begin.to_date.cweek..(Date.today.cweek-1)].reverse_each do |w|
         p w
         champ += printweek w
    end
end

if now > CUP.begin
  w = Date.today.cweek.to_i
  start_cup_week = CUP.begin.to_date.cweek.to_i
  final_week = start_cup_week + 8
  half_week = start_cup_week + 4
  cup_week = w - start_cup_week + 1
  (1..7).each do |i|
    cup += "<center>\n"
    cup += "  <br />\n"
    if i == 7
      cup += "  <h1>Финал</h1>"
      calc_week = final_week
    elsif i.between?(5, 6)
      cup += "  <h1>Полуфинал #{i-4}</h1>"
      calc_week = half_week
    else
      cup += "  <h1>Четвертьфинал #{i}</h1>"
      calc_week = start_cup_week
    end
    cup += "</center>\n"
    cup += "<div class=\"datagrid\"><table>\n"
    cup += "  <thead><tr><th>Неделя</th><th>Команда</th><th>Результат (км)</th></tr></thead>\n"
    cup += "  <tbody>\n"
    teams = db.execute("SELECT teamid FROM playoff WHERE bracket=#{i}")
    if teams[0][0] == 0 and teams[1][0] == 0
      t1 = '?'
      t2 = '?'
    else
      t1 = db.execute("SELECT teamname FROM teams WHERE teamid=#{teams[0][0]}")[0][0]
      t2 = db.execute("SELECT teamname FROM teams WHERE teamid=#{teams[1][0]}")[0][0]
    end
    (0..2).each do |n|
      d1 = (db.execute("SELECT COALESCE(distance,0) FROM teamwlog WHERE teamid=#{teams[0][0]} AND week=#{calc_week+n}")[0] || [0.0])[0]
      d2 = (db.execute("SELECT COALESCE(distance,0) FROM teamwlog WHERE teamid=#{teams[1][0]} AND week=#{calc_week+n}")[0] || [0.0])[0]
      if n == 1
        cup += "    <tr class=\"alt\"><td rowspan=\"2\">#{n+1}</td><td>#{t1}</td><td>#{d1.round(2)}</td></tr>\n"
        cup += "    <tr class=\"alt\"><td>#{t2}</td><td>#{d2.round(2)}</td></tr>\n"
      else
        cup += "    <tr><td rowspan=\"2\">#{n+1}</td><td>#{t1}</td><td>#{d1.round(2)}</td></tr>\n"
        cup += "    <tr><td>#{t2}</td><td>#{d2.round(2)}</td></tr>\n"
      end
    end
    cup += "  </tbody>\n"
    cup += "</table>\n"
    cup += "</div>\n"
  end
  cup += "<hr />\n"
end



File.open('html/index.html', 'w') { |f| f.write(index_erb.result) }
File.open('html/rules.html', 'w') { |f| f.write(rules_erb.result) }

### Process users' personal pages
data = ""
runners = db.execute("SELECT * FROM runners ORDER BY runnername")
teams = db.execute("SELECT * FROM teams")
runners.each do |r|
    note = db.execute("SELECT title FROM titles WHERE runnerid=#{r[0]}").join("<br />")
    data = ""
    data += "<center>\n"
    data += "<h1>Карточка участника</h1>\n"
    data += "</center>\n"
    data += "<div class=\"datagrid\">\n"
    data += "<table>\n"
    data += "<tbody>\n"
    data += "<tr><td><b>Имя</b></td><td>#{r[1]}</td></tr>"
    data += "<tr><td><b>Команда</b></td><td>#{r[2]==0 ? "-" : teams[r[4]-1][1]}</td></tr>"
    data += "<tr><td><b>Недельный план</b></td><td>#{(7*r[5]/365).round(2)}</td></tr>"
    data += "<tr><td><b>Достижения</b></td><td>#{note}</td></tr>"
    data += "<tr><td><b>Профиль на Страве</b></td><td><a href=\"https://strava.com/athletes/#{r[0]}\">https://strava.com/athletes/#{r[0]}</a></td></tr>"
    data += "</tbody>\n"
    data += "</table>\n"

    odd = true
    data2 = ''
    data2 += "<div class=\"datagrid\"><table>\n"
    data2 += "  <thead><tr><th>Неделя</th><th>Результат (км)</th><th>Общее время</th><th>Средний темп</th></tr></thead>\n"
    data2 += "  <tbody>\n"
    db.execute("SELECT runnerid, week, distance, strftime('%H:%M:%S',time,'unixepoch'), strftime('%M:%S',time/distance,'unixepoch') FROM wlog WHERE runnerid=#{r[0]}") do |wr|
      if odd then
        odd = false
        data2 += "  <tr><td>#{wr[1]}</td><td>#{wr[2].round(2)}</td><td>#{wr[3]}</td><td>#{wr[4]}</td></tr>\n"
      else
        odd = true
        data2 += "  <tr class='alt'><td>#{wr[1]}</td><td>#{wr[2].round(2)}</td><td>#{wr[3]}</td><td>#{wr[4]}</td></tr>\n"
      end
    end
    data2 += "  </tbody>\n"
    data2 += "</table>\n"

    File.open("html/u#{r[0]}.html", 'w') { |f| f.write(user_erb.result(binding)) }

#    Gnuplot.open do |gp|
#        Gnuplot::Plot.new(gp) do |plot|
#            plot.terminal "png"
#            plot.output File.expand_path("../html/u#{r[0]}.png", __FILE__)
#            plot.title "Километраж по неделям"
#	    plot.key "bmargin"
#            weeks = [*1..(Date.today.cweek)]
#            plot.xrange "[1:#{weeks[-1]}]"
#            plot.xlabel 'Недели'
#            plot.ylabel 'Км'
#            plot.ytics ''
#            plot.grid 'y'
#            a = [0]
#            weeks.each do |w|
#                bow = DateTime.parse(Date.commercial(2020,w).to_s).beginning_of_week.iso8601
#                eow = DateTime.parse(Date.commercial(2020,w).to_s).end_of_week.iso8601
#                d = db.execute("SELECT SUM(distance) FROM log WHERE runnerid=#{r[0]} AND date>'#{bow}' AND date<'#{eow}'")[0][0]
#                a += d.nil?? [0] : [d]
#            end
#            norm = (7*r[5]/365).round(2)
#            ymax = [a.max*1.1, norm*1.1].max
#            plot.yrange "[0:#{ymax}]"
#            p "+++++ #{r[0]} #{r[1]} ",weeks, a
#            plot.data << Gnuplot::DataSet.new( a ) do |ds|
#                ds.with = "lines lt rgb \"red\""
#                ds.linewidth = 2
#                ds.title = r[1]
#            end
#            plot.data << Gnuplot::DataSet.new(norm.to_s) do |ds|
#                ds.with = "lines lt rgb \"blue\""
#                ds.linewidth = 1
#                ds.title = "Норма=#{norm.to_s} км"
#            end
#	end
#    end
#    Gnuplot.open do |gp|
#        Gnuplot::Plot.new(gp) do |plot|
#            p "----------------- norm plot"
#            plot.terminal "png"
#            plot.output File.expand_path("../html/w#{r[0]}.png", __FILE__)
#            plot.title "Выполнение нормы"
#	    plot.key "bmargin"
#            weeks = [*1..(Date.today.cweek)]
#            plot.xrange "[1:#{weeks[-1]}]"
#            plot.xlabel 'Недели'
#            plot.ylabel 'Км'
#            plot.ytics ''
#            plot.grid 'y'
#            a = [0]
#            weeks.each do |w|
#                bow = DateTime.parse(Date.commercial(2020,w).to_s).beginning_of_week.iso8601
#                eow = DateTime.parse(Date.commercial(2020,w).to_s).end_of_week.iso8601
#                d = db.execute("SELECT SUM(distance) FROM log WHERE runnerid=#{r[0]} AND date<'#{eow}'")[0][0]
#                a += d.nil?? [0] : [d]
#            end
#            plot.yrange "[0:#{a.max*1.1}]"
#            p "+++++ #{r[0]} #{r[1]} ",weeks, a
#            plot.data << Gnuplot::DataSet.new( a ) do |ds|
#                ds.with = "lines lt rgb \"red\""
#                ds.linewidth = 2
#                ds.title = r[1]+"="+a[-1].round(2).to_s+" км"
#            end
#            norm = (7*r[5]/365).round(2)
#            plot.data << Gnuplot::DataSet.new(norm.to_s+"*x") do |ds|
#                ds.with = "lines lt rgb \"blue\""
#                ds.linewidth = 1
#                ds.title = "Норма=#{(norm*(a.length-1)).round(2)} км"
#            end
#	end
#    end
end

### Process users.html
data = ""
data += "<center>\n"
data += "<h1>По километрам</h1>\n"
data += "</center>\n"
data += "<div class=\"datagrid\">\n"
data += "<table>\n"
data += "<tbody>\n"
data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2020 (км)</th><th>Объемы 2020 (%)</th><th>Объемы 2019 (км)</th><th>Команда</th></tr></thead>\n"
odd = true
i = 0
db.execute("SELECT runnerid, runnername, teamname, (SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid) d, (SELECT goal FROM runners WHERE runnerid=r.runnerid) g, 100*(SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid)/(SELECT goal FROM runners WHERE runnerid=r.runnerid) FROM runners r JOIN teams USING (teamid) ORDER BY d DESC") do |r|
  note = db.execute("SELECT title FROM titles WHERE runnerid=#{r[0]}").join("<br />")
  if odd
    if r[3]>dayno*r[4]/365
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  else
    if r[3]>dayno*r[4]/365
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  end
  odd = !odd
end
data += "</tbody>\n"
data += "</table>\n"
data += "</div>\n"
data += "<br />\n"
File.open("html/users.html", 'w') { |f| f.write(users_erb.result(binding)) }

### Process users2.html
data = ""
data += "<center>\n"
data += "<h1>По процентам</h1>\n"
data += "</center>\n"
data += "<div class=\"datagrid\">\n"
data += "<table>\n"
data += "<tbody>\n"
data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2020 (%)</th><th>Объемы 2020 (км)</th><th>Объемы 2019 (км)</th><th>Команда</th></tr></thead>\n"
odd = true
i = 0
db.execute("SELECT runnerid, runnername, teamname, (SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid) d, (SELECT goal FROM runners WHERE runnerid=r.runnerid) g, 100*(SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid)/(SELECT goal FROM runners WHERE runnerid=r.runnerid) p FROM runners r JOIN teams USING (teamid) ORDER BY p DESC") do |r|
  note = db.execute("SELECT title FROM titles WHERE runnerid=#{r[0]}").join("<br />")
  if odd
    if r[3]>dayno*r[4]/365
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  else
    if r[3]>dayno*r[4]/365
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  end
  odd = !odd
end
data += "</tbody>\n"
data += "</table>\n"
data += "</div>\n"
data += "<br />\n"
File.open("html/users2.html", 'w') { |f| f.write(users2_erb.result(binding)) }

### Process users3.html
data = ""
data += "<center>\n"
data += "<h1>По результатам 2019 года</h1>\n"
data += "</center>\n"
data += "<div class=\"datagrid\">\n"
data += "<table>\n"
data += "<tbody>\n"
data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2019 (км)</th><th>Объемы 2020 (км)</th><th>Объемы 2020 (%)</th><th>Команда</th></tr></thead>\n"
odd = true
i = 0
db.execute("SELECT runnerid, runnername, teamname, (SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid) d, (SELECT goal FROM runners WHERE runnerid=r.runnerid) g, 100*(SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid)/(SELECT goal FROM runners WHERE runnerid=r.runnerid) p FROM runners r JOIN teams USING (teamid) ORDER BY g DESC") do |r|
  note = db.execute("SELECT title FROM titles WHERE runnerid=#{r[0]}").join("<br />")
  if odd
    if r[3]>dayno*r[4]/365
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  else
    if r[3]>dayno*r[4]/365
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  end
  odd = !odd
end
data += "</tbody>\n"
data += "</table>\n"
data += "</div>\n"
data += "<br />\n"
File.open("html/users3.html", 'w') { |f| f.write(users3_erb.result(binding)) }

### Process users4.html
data = ""
data += "<center>\n"
data += "<h1>Команды и участники</h1>\n"
data += "</center>\n"
db.execute("SELECT * FROM teams ORDER BY teamid") do |t|
    data += "<center>\n"
    data += "<h2>#{t[1]}</h2>\n"
    data += "</center>\n"
    data += "<div class=\"datagrid\">\n"
    data += "<table>\n"
    data += "<tbody>\n"
    data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2019 (км/год)</th><th>Примечания</th></tr></thead>\n"
    odd = true
    i = 0
    db.execute("SELECT * FROM runners WHERE teamid=#{t[0]} ORDER BY goal DESC") do |r|
        note = db.execute("SELECT title FROM titles WHERE runnerid=#{r[0]}").join("<br />")
        dist = db.execute("SELECT SUM(distance) FROM wlog WHERE runnerid=#{r[0]}")[0][0]
        if odd
          if dist>dayno*r[5]/365
            data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          else
            data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          end
        else
          if dist>dayno*r[5]/365
            data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          else
            data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          end
        end
        odd = !odd
    end
    data += "</tbody>\n"
    data += "</table>\n"
    data += "</div>\n"
    data += "<br />\n"
end
File.open("html/users4.html", 'w') { |f| f.write(users4_erb.result(binding)) }

### Process teams*.html
[*CHAMP.begin.to_date.cweek..(Date.today.cweek)].reverse_each do |w|
     puts "teams#{w}...."
     p w
     bow = DateTime.parse(Date.commercial(2020,w).to_s).beginning_of_week
     eow = DateTime.parse(Date.commercial(2020,w).to_s).end_of_week
     p bow.iso8601, eow.iso8601
     teams = db.execute("SELECT * FROM teams")
     data = ""
     db.execute("SELECT * FROM teams") do |t|
         p t
         data +=   "<center>\n"
         data +=   "    <br />\n"
         data +=   "    <br />\n"
         data +=   "    <h1>#{t[1]}</h1>\n"
         data +=   "</center>\n"
         data +=   "<div class=\"datagrid\"><table>\n"
         data +=   "   <thead><tr><th>Имя</th><th>Цель (км/нед)</th><th>Результат (км)</th><th>Выполнено (%)</th></tr></thead>\n"
         data +=   "    <tbody>\n"
         sum_dist = 0
         sum_pct = 0
         sum_goal = 0
         odd = true
         runners = db.execute("SELECT * FROM runners WHERE teamid=#{t[0]} ORDER BY goal DESC")
         runners.each do |r|
             dist = db.execute("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{r[0]} AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}'")[0][0]
             goal = 7*r[5]/365
             pct = (dist/goal)*100
             sum_dist += dist
             sum_pct += pct
             sum_goal += goal
             if odd
                 data += "  <tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{goal.round(2)}</td><td><a href=\"https://strava.com/athletes/#{r[0]}#interval?interval=#{CHAMP.begin.year.to_s+w.to_s.rjust(2,"0")}&interval_type=week&chart_type=miles&year_offset=0\">#{dist.round(2)}</a></td><td>#{pct.round(2)}</td></tr>\n"
             else
                 data += "  <tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{goal.round(2)}</td><td><a href=\"http://strava.com/athletes/#{r[0]}#interval?interval=#{CHAMP.begin.year.to_s+w.to_s.rjust(2,"0")}&interval_type=week&chart_type=miles&year_offset=0\">#{dist.round(2)}</a></td><td>#{pct.round(2)}</td></tr>\n"
             end
             odd = !odd
         end
         data +=  "<tfoot><tr><td>Всего:</td><td>#{sum_goal.round(2)}</td><td>#{sum_dist.round(2)}</td><td>#{(100*sum_dist/sum_goal).round(2)}</td></tr></tfoot>\n"
         data +=   "   </tbody>\n"
         data +=   "</table>\n"
         data +=   "</div>\n"
     end
     box  = "<nav class=\"sub\">\n"
     box += "      <ul>\n"
     (CHAMP.begin.to_date.cweek..Date.today.cweek).each do |wk|
         if wk == w
             box += "        <li class=\"active\"><span>#{wk} неделя</span></li>\n"
         else
             box += "        <li><a href=\"teams#{wk}.html\">#{wk} неделя</a></li>\n"
         end
     end
     box += "      </ul>\n"
     box += "    </nav>\n"
     File.open("html/teams#{w}.html", 'w') { |f| f.write(teams_erb.result(binding)) }
end

### Process statistics*.html
[*CHAMP.begin.to_date.cweek..(Date.today.cweek)].reverse_each do |w|
     puts "statistics#{w}...."
     p w
     bow = DateTime.parse(Date.commercial(2020,w).to_s).beginning_of_week
     eow = DateTime.parse(Date.commercial(2020,w).to_s).end_of_week
     p bow.iso8601, eow.iso8601
     data = ""
     data +=   "<center>\n"
     data +=   "    <br />\n"
     data +=   "    <br />\n"
     data +=   "    <h1>Чудеса недели</h1>\n"
     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th></th><th>Имя</th><th>Команда</th><th>Результат (км)</th></tr></thead>\n"
     data +=   "    <tbody>\n"

#     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
#                         (SELECT runnerid, SUM(distance) d FROM log \
#                                WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
#                                    WHERE runners.runnerid=l.runnerid AND sex=1 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mlw'")[0] || [0,'',0,'']
     data +=   "    <tr><td>Больше всех километров среди мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
#                         (SELECT runnerid, SUM(distance) d FROM log \
#                                WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
#                                    WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='flw'")[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Больше всех километров среди женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT log.runnerid, runnername, MAX(distance), runid, teamname FROM log, runners, teams WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND runners.runnerid=log.runnerid AND sex=1 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mlr'")[0] || [0,'',0,'']
     data +=   "    <tr><td>Самая длинная тренировка у мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT log.runnerid, runnername, MAX(distance), runid, teamname FROM log, runners, teams WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND runners.runnerid=log.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='flr'")[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Самая длинная тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT log.runnerid, runnername, strftime('%H:%M:%S',MAX(time),'unixepoch'), runid, teamname FROM log, runners, teams WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND runners.runnerid=log.runnerid AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || ''
#     data +=   "    <tr><td>Самая продолжительная тренировка</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[4]}</td><td><a href='http://strava.com/activities/#{x[3]}'>#{x[2]}</a></td></tr>\n"
#
#     x = db.execute("SELECT log.runnerid, runnername, strftime('%H:%M:%S',MAX(time),'unixepoch'), runid, teamname FROM log, runners, teams WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND runners.runnerid=log.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || ''
#     data +=   "    <tr class='alt'><td>Самая продолжительная тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[4]}</td><td><a href='http://strava.com/activities/#{x[3]}'>#{x[2]}</a></td></tr>\n"

#     x = db.execute("SELECT log.runnerid, runnername, strftime('%M:%S',MIN(time/distance),'unixepoch'), runid, distance, teamname FROM log, runners, teams WHERE log.runnerid=runners.runnerid AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND sex=1 AND teams.teamid=runners.teamid AND time>0")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || 0
#     x[5] = x[5] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mfr'")[0] || [0,'',0,'']
     data +=   "    <tr><td>Самая быстрая тренировка у мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT log.runnerid, runnername, strftime('%M:%S',MIN(time/distance),'unixepoch'), runid, distance, teamname FROM log, runners, teams WHERE log.runnerid=runners.runnerid AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND sex=0 AND teams.teamid=runners.teamid AND time>0")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || 0
#     x[5] = x[5] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='ffr'")[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Самая быстрая тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT l.runnerid, runnername, strftime('%M:%S',MIN(t/d),'unixepoch'), teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND sex=1 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mfw'")[0] || [0,'',0,'']
     data +=   "    <tr><td>Самый быстрый средний темп у мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT l.runnerid, runnername, strftime('%M:%S',MIN(t/d),'unixepoch'), teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || ''
     x = db.execute("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='ffw'")[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Самый быстрый средний темп у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

#     x = db.execute("SELECT log.runnerid, runnername, strftime('%M:%S',MAX(time/distance),'unixepoch'), runid, distance, teamname FROM log, runners, teams WHERE log.runnerid=runners.runnerid AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND teams.teamid=runners.teamid AND time>0")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || 0
#     x[5] = x[5] || ''
#     data +=   "    <tr><td>Самая медленная тренировка</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[5]}</td><td><a href='http://strava.com/activities/#{x[3]}'>#{x[2]} мин/км (#{x[4].round(2)} км)</a></td></tr>\n"
#
#     x = db.execute("SELECT log.runnerid, runnername, strftime('%M:%S',MAX(time/distance),'unixepoch'), runid, distance, teamname FROM log, runners, teams WHERE log.runnerid=runners.runnerid AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND sex=0 AND teams.teamid=runners.teamid AND time>0")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || 0
#     x[4] = x[4] || 0
#     x[5] = x[5] || ''
#     data +=   "    <tr class='alt'><td>Самая медленная тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[5]}</td><td><a href='http://strava.com/activities/#{x[3]}'>#{x[2]} мин/км (#{x[4].round(2)} км)</a></td></tr>\n"
#
#     x = db.execute("SELECT l.runnerid, runnername, strftime('%M:%S',MAX(t/d),'unixepoch'), teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || ''
#     data +=   "    <tr><td>Самый медленный средний темп</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]} мин/км</td></tr>\n"
#
#     x = db.execute("SELECT l.runnerid, runnername, strftime('%M:%S',MAX(t/d),'unixepoch'), teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
#     p x
#     x[0] = x[0] || 0
#     x[1] = x[1] || ''
#     x[2] = x[2] || 0
#     x[3] = x[3] || ''
#     data +=   "    <tr class='alt'><td>Самый медленный средний темп у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]} мин/км</td></tr>\n"
     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
                        (SELECT runnerid, 100*SUM(distance)/(SELECT 7*goal/365 FROM runners WHERE runnerid=log.runnerid) d \
                                FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND sex=1 AND teams.teamid=runners.teamid")[0] || [0,'',0,'']
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr><td>Больше всех процентов среди мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)}%</td></tr>\n"

     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
                        (SELECT runnerid, 100*SUM(distance)/(SELECT 7*goal/365 FROM runners WHERE runnerid=log.runnerid) d \
                                FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0] || [0,'',0,'']
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr class='alt'><td>Больше всех процентов среди женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)}%</td></tr>\n"


     x = db.execute(" SELECT teamname, strftime('%M:%S',MIN(time/distance),'unixepoch') FROM teamwlog l, teams t WHERE l.teamid=t.teamid AND week=#{w}")[0]
     data += "    <tr><td>Самая быстрая команда</td><td></td><td>#{x[0]}</td><td>#{x[1]}</td></tr>\n"

     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<br />\n"
     data +=   "<center>\n"
     data +=   "    <br />\n"
     data +=   "    <br />\n"
     data +=   "    <h1>Раздача слонов за год</h1>\n"
     data +=   "    <h2>командам</h2>\n"
     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th>Команда</th><th>Очки</th></tr></thead>\n"
     data +=   "    <tbody>\n"
     x = db.execute("SELECT COALESCE(teamname, ''), count(*) c FROM wonders w LEFT JOIN teams t ON w.teamid=t.teamid WHERE w.week<=#{w} GROUP BY w.teamid ORDER BY c DESC")
     odd = false
     x.each do |r|
       if odd
         data += "  <tr><td>#{r[0]}</td><td>#{r[1]*2}</td></tr>\n"
       else
         data += "  <tr class=\"alt\"><td>#{r[0]}</td><td>#{r[1]*2}</td></tr>\n"
       end
       odd = !odd
     end
     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<center>\n"
     data +=   "    <br />\n"
     data +=   "    <br />\n"
     data +=   "    <h2>и участникам</h2>\n"
     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th>Имя</th><th>Команда</th><th>Очки</th></tr></thead>\n"
     data +=   "    <tbody>\n"
     x = db.execute("SELECT runnername, COALESCE(teamname, ''), count(*) c FROM runners r, wonders w LEFT JOIN teams t ON w.teamid=t.teamid WHERE w.runnerid=r.runnerid AND w.week<=#{w} GROUP BY w.runnerid ORDER BY c DESC")
     odd = false
     x.each do |r|
       if odd
         data += "  <tr><td>#{r[0]}</td><td>#{r[1]}</td><td>#{r[2]*2}</td></tr>\n"
       else
         data += "  <tr class=\"alt\"><td>#{r[0]}</td><td>#{r[1]}</td><td>#{r[2]*2}</td></tr>\n"
       end
       odd = !odd
     end
     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<br />\n"

     box  = "<nav class=\"sub\">\n"
     box += "      <ul>\n"
     (CHAMP.begin.to_date.cweek..Date.today.cweek).each do |wk|
         if wk == w
             box += "        <li class=\"active\"><span>#{wk} неделя</span></li>\n"
         else
             box += "        <li><a href=\"statistics#{wk}.html\">#{wk} неделя</a></li>\n"
         end
     end
     box += "      </ul>\n"
     box += "    </nav>\n"
     File.open("html/statistics#{w}.html", 'w') { |f| f.write(statistics_erb.result(binding)) }
end

#(CHAMP.begin.to_date.cweek..Date.today.cweek).each do |w|
#    p "plot for week #{w}"
#    Gnuplot.open do |gp|
#        Gnuplot::Plot.new(gp) do |plot|
#            plot.terminal "png"
#            plot.output File.expand_path("../html/cup#{w}.png", __FILE__)
#            plot.title 'Кубок'
#	    plot.key "bmargin"
#            weeks = db.execute("SELECT DISTINCT week FROM points WHERE week <= #{w} ORDER BY week").map { |i| i[0] }
#            plot.xrange "[1:#{weeks[-1]}]"
#            plot.xlabel 'Недели'
#            plot.ylabel 'Очки'
#            plot.ytics ''
#            plot.grid 'y'
#            (1..TEAMS).each do |t|
#                team = db.execute("SELECT teamname FROM teams WHERE teamid=#{t}")[0][0]
#                a = [0] + db.execute("SELECT teamid, week, (SELECT SUM(points) FROM points WHERE week<=p.week AND teamid=p.teamid) FROM points p WHERE teamid=#{t} AND week <= #{w} ORDER BY week").map { |i| i[2] }
#                p weeks, a
#		plot.data << Gnuplot::DataSet.new( a ) do |ds|
#		    ds.with = "lines"
#		    ds.linewidth = 2
#		    ds.title = team
#		end
#	    end
#	end
#    end
#end
#

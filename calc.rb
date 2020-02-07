#!/usr/bin/ruby -W0
require 'sqlite3'
require 'active_support'
require 'active_support/core_ext'
require 'pp'
require_relative './config.rb'

def calcweek (now)
    week_number = now.to_date.cweek.to_i
    db = SQLite3::Database.new(DB)
    teams = []
    (1..TEAMS).each do |t|
        num_of_runners = db.execute("SELECT COUNT(*) FROM runners WHERE teamid=#{t}")[0][0]
        tdist = 0
        sum_pct = 0
        db.execute("SELECT runnerid, goal*7/365.0 FROM runners WHERE teamid=#{t}") do |r|
            dist = db.execute("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{r[0]} AND date>'#{now.beginning_of_week.iso8601}' AND date<'#{now.end_of_week.iso8601}'")[0][0]
            goal = r[1]
            sum_pct += (dist/goal)*100
            tdist += dist
        end
        teams << [t, week_number, sum_pct/num_of_runners, tdist]
    end
    teams.sort! { |x,y| y[2] <=> x[2] }
    teams.each do |t|
        place = teams.index(t)+1
        points = 5*(TEAMS-place)
        p          "INSERT OR REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]}, #{t[3]})"
        db.execute("INSERT OR REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]}, #{t[3]})")
        db.execute("INSERT OR REPLACE INTO cup VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]}, #{t[3]})")
    end
end

def calcwlog(d)
    week_number = d.to_date.cweek.to_i
    bow = d.beginning_of_week.iso8601
    eow = d.end_of_week.iso8601
    teamdist = Hash.new(0)
    teamtime = Hash.new(0)
    teamgoal = Hash.new(0)
    db = SQLite3::Database.new(DB)
    db.execute("SELECT runnerid, teamid, 7*goal/365 from runners where teamid>0") do |r|
      res = db.execute("SELECT COALESCE(SUM(distance),0), COALESCE(SUM(time),0) FROM log, runners WHERE log.runnerid=runners.runnerid AND log.runnerid=#{r[0]} AND date>'#{bow}' AND date<'#{eow}'")[0]
      pp "r=",r
      pp "res=", res
      db.execute("INSERT OR REPLACE INTO wlog VALUES (#{r[0]}, #{week_number}, #{res[0]}, #{res[1]})")
      teamdist[r[1]] += res[0]
      teamtime[r[1]] += res[1]
      teamgoal[r[1]] += r[2]
    end
    p teamdist,teamtime,teamgoal
    teamdist.each do |team, distance|
      if team
        p("INSERT OR REPLACE INTO teamwlog VALUES (#{team}, #{week_number}, #{distance}, #{teamtime[team]}, #{teamgoal[team]})")
        db.execute("INSERT OR REPLACE INTO teamwlog VALUES (#{team}, #{week_number}, #{distance}, #{teamtime[team]}, #{teamgoal[team]})")
      end
    end
end

def calcwonders(d)
    week_number = d.to_date.cweek.to_i
    bow = d.beginning_of_week.iso8601
    eow = d.end_of_week.iso8601
    db = SQLite3::Database.new(DB)
    # best boy in week mileage
    p("SELECT r,t,MAX(d) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 GROUP BY log.runnerid)")
    w = db.execute("SELECT r,t,MAX(d) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 GROUP BY log.runnerid)")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mlw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mlw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')")
    # best girl in week mileage
    p("SELECT r,t,MAX(d) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 GROUP BY log.runnerid)")
    w = db.execute("SELECT r,t,MAX(d) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 GROUP BY log.runnerid)")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'flw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'flw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')")
    # best boy in week speed
    p("SELECT r,t,MIN(s) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 GROUP BY log.runnerid) WHERE s>0")
    w = db.execute("SELECT r,t,MIN(s) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 GROUP BY log.runnerid) WHERE s>0")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mfw', #{w[0]}, #{w[1]}, strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mfw', #{w[0]}, #{w[1]}, strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км')")
    # best girl in week speed
    p("SELECT r,t,MIN(s) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 GROUP BY log.runnerid) WHERE s>0")
    w = db.execute("SELECT r,t,MIN(s) FROM (SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 GROUP BY log.runnerid) WHERE s>0")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'ffw', #{w[0]}, #{w[1]}, strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'ffw', #{w[0]}, #{w[1]}, strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км')")
    # best boy in run mileage
    p("SELECT log.runnerid, teamid, MAX(distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1")
    w = db.execute("SELECT log.runnerid, teamid, MAX(distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mlr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mlr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')")
    # best girl in run mileage
    p("SELECT log.runnerid, teamid, MAX(distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0")
    w = db.execute("SELECT log.runnerid, teamid, MAX(distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'flr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'flr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')")
    # best boy in run speed
    p("SELECT log.runnerid, teamid, MIN(time/distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND time>0 AND distance>3.0")
    w = db.execute("SELECT log.runnerid, teamid, MIN(time/distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND time>0 AND distance>3.0")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mfr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">'||strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км</a>')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'mfr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">'||strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км</a>')")
    # best girl in run speed
    p("SELECT log.runnerid, teamid, MIN(time/distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND time>0 AND distance>3.0")
    w = db.execute("SELECT log.runnerid, teamid, MIN(time/distance),runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND time>0 AND distance>3.0")[0]
    p("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'ffr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">'||strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км</a>')")
    db.execute("INSERT OR REPLACE INTO wonders VALUES (#{week_number}, 'ffr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">'||strftime('%M:%S',#{w[2]},'unixepoch')||' мин/км</a>')")
end

def calcpoints (d)
    week_number = d.to_date.cweek.to_i
    bow = d.beginning_of_week.iso8601
    eow = d.end_of_week.iso8601
    db = SQLite3::Database.new(DB)
    place = 0
    db.execute("SELECT teamid, 100*distance/goal, distance, goal FROM teamwlog WHERE week=#{week_number} ORDER BY distance/goal") do |t|
        wonders = db.execute("SELECT count(*) FROM wonders WHERE teamid=#{t[0]} AND week=#{week_number}")[0][0]
        points = place * 5 + wonders * 2
        place += 1
        p ("INSERT OR REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[1]}, #{t[2]}, #{t[3]})")
        db.execute("INSERT OR REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[1]}, #{t[2]}, #{t[3]})")
    end
end
#def calcprolog ()
#    db = SQLite3::Database.new(DB)
#    teams = Array.new(TEAMS, 0)
#    runners = db.execute("SELECT * FROM runners") 
#    runners.each do |r|
#        r << db.execute("SELECT COALESCE(SUM(distance),0) AS d FROM log WHERE runnerid=#{r[0]} AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}' LIMIT 3")[0][0]
#    end
#    p runners
#    runners.sort! { |x,y| y[4] <=> x[4] }
#    p runners
#    teams[runners[0][2]] += 20
#    teams[runners[1][2]] += 10
#    teams[runners[2][2]] += 5
#    teams.each_with_index do |t, i|
#        db.execute("INSERT OR REPLACE INTO points VALUES (#{i}, 1, #{t}, 0.0)")
#    end
#end

now = Time.now.getutc

if now < PROLOG.begin or now > (CHAMP.end + 2.days)
    puts "#{now}: Not yet time..."
    exit
end

if now >= PROLOG.begin and now <= (PROLOG.end + 2.days)
  if now.wday.between?(1, DOW-1) and 1.week.ago.getutc.beginning_of_week >= PROLOG.begin
    calcwlog(1.week.ago)
#    calcwonders(1.week.ago)
  end
  calcwlog(now)
#  calcwonders(now)
end

if now >= CHAMP.begin and now <= (CHAMP.end + 2.days)
  if now.wday.between?(1, DOW-1) and 1.week.ago.getutc.beginning_of_week >= CHAMP.begin
    calcwlog(1.week.ago)
    calcwonders(1.week.ago)
    calcpoints(1.week.ago)
  end
  calcwlog(now)
  calcwonders(now)
  calcpoints(now)
end


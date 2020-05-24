#!/usr/bin/ruby -W0
require 'csv'
require 'sqlite3'
require 'httpclient'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require_relative './config.rb'

def auth (reftoken)
    c = HTTPClient.new
    loginurl = "https://www.strava.com/oauth/token"
    data = { "client_id" => CLIENT_ID, "client_secret" => CLIENT_SECRET, "grant_type" => "refresh_token", "refresh_token" => reftoken}
    resp = c.post(loginurl, data)
    j = JSON.parse(resp.content)
    return j['access_token']
end

$stdout.sync = true
now = Time.now.getutc
if now < PROLOG.begin or now > CUP.end
    puts "#{now}: Not yet time..."
    exit
end
if now.wday.between?(1,DOW-1)
    getstart = 1.week.ago.getutc.beginning_of_week
else
    getstart = now.beginning_of_week
end
if getstart < PROLOG.begin
    getstart = PROLOG.begin
end
getend = now.end_of_week
if getend > CUP.end
    getend = CUP.end
end
p getstart
p getend
p now

conn = HTTPClient.new
db = SQLite3::Database.new(DB)
url = "https://www.strava.com/api/v3/athlete/activities"
p url
db.execute("DELETE FROM log WHERE date>'#{getstart.iso8601}' and date<'#{getend.iso8601}'")

db.execute("SELECT runnerid, runnerid, reftoken, runnername, teamid, goal FROM runners WHERE reftoken IS NOT NULL") do |r|
    rid, sid, reftoken, rname, tid, goal = r 
    puts "#{rid}, #{sid}: #{rname}"
    token = auth(reftoken)
    after = getstart.to_i
    before = getend.to_i
    d = {"after" => after, "before" => before, "per_page" => 100}
    h = {"Authorization" => "Bearer #{token}"}
    #   resp = c.post(url, {"after" => after, "before" => before, "per_page" => 300}, {"Authorization" => "Bearer #{token}"})
    resp = conn.get(url, d, h)
    i = db.prepare("INSERT OR REPLACE INTO log (runid, runnerid, date, distance, time, type, workout_type, commute, private, start_date_local, timezone, utc_offset, name, elapsed_time, total_elevation_gain, start_latitude, start_longitude, end_latitude, end_longitude, location_city, location_state, location_country, kudos_count, comment_count, photo_count, summary_polyline, gear_id, visibility) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
    if resp.status == 200 then
        j = JSON.parse(resp.content)
        j.each do |run|
          p run
          id = run['id']
          type = run['type']
          distance = run['distance']
          start_date = run['start_date']
          moving_time = run['moving_time']
          workout_type = run['workout_type'] || 0
          start_date_local = run['start_date_local'] || ''
          timezone = run['timezone'] || ''
          utc_offset = run['utc_offset'] || 0
          name = run['name'] || ''
          elapsed_time = run['elapsed_time'] || ''
          total_elevation_gain = run['total_elevation_gain'] || 0.0
          start_latitude = run['start_latitude'] || 0.0
          start_longitude = run['start_longitude'] || 0.0
          end_latitude = run['end_latlng'] ? run['end_latlng'][0] : 0.0
          end_longitude = run['end_latlng'] ? run['end_latlng'][1] : 0.0
          location_city = run['location_city'] || ''
          location_state = run['location_state'] || ''
          location_country = run['location_country'] || ''
          kudos_count = run['kudos_count'] || 0
          comment_count = run['comment_count'] || 0
          photo_count = run['photo_count'] || 0
          summary_polyline = run['map']['summary_polyline'] || ''
          gear_id = run['gear_id'] || ''
          visibility = run['visibility'] || ''
          private = run['private'] ? 1 : 0
          commute = run['commute'] ? 1 : 0
          if type == 'Run' or type == 'VirtualRun'
#            p "INSERT OR REPLACE INTO log (runid, runnerid, date, distance, time, type, workout_type, commute, private, start_date_local, timezone, utc_offset, name, elapsed_time, total_elevation_gain, start_latitude, start_longitude, end_latitude, end_longitude, location_city, location_state, location_country, kudos_count, comment_count, photo_count, summary_polyline) VALUES(#{id}, #{rid}, '#{start_date}', #{distance/1000}, #{moving_time.to_i}, '#{type}', #{workout_type}, #{commute}, #{private}, '#{start_date_local}', '#{timezone}', #{utc_offset}, '#{name}', #{elapsed_time}, #{total_elevation_gain}, #{start_latitude}, #{start_longitude}, #{end_latitude}, #{end_longitude}, '#{location_city}', '#{location_state}', '#{location_country}', #{kudos_count}, #{comment_count}, #{photo_count}, '#{summary_polyline}')"
#            db.execute("INSERT OR REPLACE INTO log (runid, runnerid, date, distance, time, type, workout_type, commute, private, start_date_local, timezone, utc_offset, name, elapsed_time, total_elevation_gain, start_latitude, start_longitude, end_latitude, end_longitude, location_city, location_state, location_country, kudos_count, comment_count, photo_count, summary_polyline) VALUES(#{id}, #{rid}, '#{start_date}', #{distance/1000}, #{moving_time.to_i}, '#{type}', #{workout_type}, #{commute}, #{private}, '#{start_date_local}', '#{timezone}', #{utc_offset}, '#{name}', #{elapsed_time}, #{total_elevation_gain}, #{start_latitude}, #{start_longitude}, #{end_latitude}, #{end_longitude}, '#{location_city}', '#{location_state}', '#{location_country}', #{kudos_count}, #{comment_count}, #{photo_count}, '#{summary_polyline}')")
            i.execute(id, rid, start_date, distance/1000, moving_time.to_i, type, workout_type, commute, private, start_date_local, timezone, utc_offset, name, elapsed_time, total_elevation_gain, start_latitude, start_longitude, end_latitude, end_longitude, location_city, location_state, location_country, kudos_count, comment_count, photo_count, summary_polyline, gear_id, visibility)
          end
        end
    else
        print "ERROR: response code #{resp.status}, content: #{resp.content}"
    end
end

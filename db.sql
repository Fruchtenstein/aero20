CREATE TABLE IF NOT EXISTS "runners" (runnerid INTEGER PRIMARY KEY, runnername, username, email, teamid INTEGER, goal REAL, sex INT, acctoken, reftoken, city, state, country);
CREATE TABLE IF NOT EXISTS "log" (runid INTEGER PRIMARY KEY, runnerid INTEGER, date, distance REAL, time, type, workout_type INT, commute INT, private INT, start_date_local, timezone, utc_offset, name, elapsed_time, total_elevation_gain REAL, start_latitude REAL, start_longitude REAL, end_latitude REAL, end_longitude REAL, location_city, location_state, location_country, kudos_count INT, comment_count INT, photo_count INT, summary_polyline, gear_id, visibility);
CREATE TABLE IF NOT EXISTS "points" (teamid INTEGER, week INTEGER, points INTEGER, pcts REAL, distance REAL, goal REAL, PRIMARY KEY(teamid, week));
CREATE TABLE IF NOT EXISTS "teams" (teamid INTEGER PRIMARY KEY, teamname, goal REAL);
CREATE TABLE IF NOT EXISTS "titles" (runnerid INTEGER, date, title);
CREATE TABLE IF NOT EXISTS "wlog" (runnerid INTEGER, week INTEGER, distance REAL, time, PRIMARY KEY(runnerid, week));
CREATE TABLE IF NOT EXISTS "teamwlog" (teamid INTEGER, week INTEGER, distance REAL, time, goal REAL, PRIMARY KEY(teamid, week));
CREATE TABLE IF NOT EXISTS "wonders" (week INT, type, runnerid INT, teamid INT, wonder, PRIMARY KEY(week,type));
CREATE TABLE playoff (teamid INTEGER, bracket INTEGER, wins INTEGER DEFAULT 0);

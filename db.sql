CREATE TABLE IF NOT EXISTS "runners" (runnerid INTEGER PRIMARY KEY, runnername, username, email, teamid INTEGER, goal REAL, sex INT, acctoken, reftoken);
CREATE TABLE IF NOT EXISTS "log" (runid INTEGER PRIMARY KEY, runnerid INTEGER, date, distance REAL, time, type, workout_type INT, commute INT);
CREATE TABLE IF NOT EXISTS "points" (teamid INTEGER, week INTEGER, points INTEGER, pcts REAL, distance REAL, goal REAL, PRIMARY KEY(teamid, week));
CREATE TABLE IF NOT EXISTS "teams" (teamid INTEGER PRIMARY KEY, teamname, goal REAL);
CREATE TABLE IF NOT EXISTS "titles" (runnerid INTEGER, date, title);
CREATE TABLE IF NOT EXISTS "wlog" (runnerid INTEGER, week INTEGER, distance REAL, time, PRIMARY KEY(runnerid, week));
CREATE TABLE IF NOT EXISTS "wonders" (week INT, type, runnerid INT, teamid INT, wonder REAL, PRIMARY KEY(week,type));
CREATE TABLE IF NOT EXISTS "teamwlog" (teamid INTEGER, week INTEGER, distance REAL, time, PRIMARY KEY(teamid, week));

#!/usr/bin/ruby -W0
require 'sqlite3'
require 'active_support'
require 'active_support/core_ext'
require_relative './config.rb'

db = SQLite3::Database.new(DB)
teams = Array.new(TEAMS) {Array.new}
goals = Array.new(TEAMS,0)

db.execute("SELECT runnerid, runnername, goal FROM runners WHERE NOT runnerid=1662188 ORDER BY goal DESC").each do |r|
  goesto = goals.index(goals.min)
  teams[goesto] << [r[1],r[2]]
  goals[goesto] += 7*r[2]/365
  db.execute("UPDATE runners SET teamid=#{goesto+1} WHERE runnerid=#{r[0]}")
end

pp teams
pp goals

pp db.execute("select teamid, runnername, goal from runners WHERE NOT runnerid=1662188 order by teamid,goal desc")

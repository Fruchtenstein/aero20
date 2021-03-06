require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'sqlite3'
require_relative './config.rb'

enable :sessions
set :port => 28538, :bind => '127.0.0.1'

get '/r2020' do
    erb :r2020
end

get '/reg1' do
    if request['code'].nil?
        puts "No code"
        erb :reg1fail
    else
        begin
            retries ||= 0
            puts "code is #{request['code']}"
            uri = URI.parse("https://www.strava.com")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            rq = Net::HTTP::Post.new("/oauth/token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&code=#{request['code']}&grant_type=authorization_code")
            response = http.request(rq)
        rescue => e
            puts 'Strava error, retry:', $!, $@
            sleep 1
            retry if (retries += 1) < 3
        end
        j = JSON.parse(response.body)
        puts j
        session[:sid]=j['athlete']['id']
        session[:uname]=j['athlete']['username']
        session[:fname]=j['athlete']['firstname']
        session[:lname]=j['athlete']['lastname']
        session[:city]=j['athlete']['city']
        session[:state]=j['athlete']['state']
        session[:country]=j['athlete']['country']
        session[:sex]=j['athlete']['sex']=='F' ? 0 : 1
        session[:acctoken]=j['access_token']
        session[:reftoken]=j['refresh_token']
        db = SQLite3::Database.new("../aero20/2020.db")
        email, volume = db.execute("select email, goal from runners where runnerid=#{j['athlete']['id']}")[0]
        session[:email]=email
        session[:volume]=volume
        erb :reg1
    end
end

get '/reg2' do
    begin
        p :locals
        retries ||= 0
        db = SQLite3::Database.new("../aero20/2020.db")
        fullname="#{params[:fname]} #{params[:lname]}"
#        p("INSERT OR REPLACE INTO runners VALUES (#{session[:sid]},'#{fullname}', '#{session[:uname]}', '#{params[:email]}', 0, #{params[:volume].to_f}, #{session[:sex]}, '#{session[:acctoken]}', '#{session[:reftoken]}', '#{session[:city]}', '#{session[:state]}', '#{session[:country]}')")
#        db.execute("INSERT OR REPLACE INTO runners VALUES (#{session[:sid]},'#{fullname}', '#{session[:uname]}', '#{params[:email]}', 0, #{params[:volume].to_f}, #{session[:sex]}, '#{session[:acctoken]}', '#{session[:reftoken]}', '#{session[:city]}', '#{session[:state]}', '#{session[:country]}')")
#        p "UPDATE runners SET runnername='#{fullname}', username='#{session[:uname]}', email='#{params[:email]}', goal=#{params[:volume]}, sex=#{session[:sex]}, acctoken='#{session[:acctoken]}', reftoken='#{session[:reftoken]}', city='#{session[:city]}', state='#{session[:state]}', country='#{session[:country]}' WHERE runnerid=#{session[:sid]}"
#        db.execute("UPDATE runners SET runnername='#{fullname}', username='#{session[:uname]}', email='#{params[:email]}', goal=#{params[:volume]}, sex=#{session[:sex]}, acctoken='#{session[:acctoken]}', reftoken='#{session[:reftoken]}', city='#{session[:city]}', state='#{session[:state]}', country='#{session[:country]}' WHERE runnerid=#{session[:sid]}")
#        p "UPDATE runners SET acctoken='#{session[:acctoken]}', reftoken='#{session[:reftoken]}' WHERE runnerid=#{session[:sid]}"
#        db.execute("UPDATE runners SET acctoken='#{session[:acctoken]}', reftoken='#{session[:reftoken]}' WHERE runnerid=#{session[:sid]}")
        p("INSERT OR REPLACE INTO runners VALUES (#{session[:sid]},'#{fullname}', '#{session[:uname]}', '#{params[:email]}', 0, #{params[:volume]}, #{session[:sex]}, '#{session[:acctoken]}', '#{session[:reftoken]}', '#{session[:city]}', '#{session[:state]}', '#{session[:country]}')")
        db.execute("INSERT OR REPLACE INTO runners VALUES (#{session[:sid]},'#{fullname}', '#{session[:uname]}', '#{params[:email]}', 0, #{params[:volume]}, #{session[:sex]}, '#{session[:acctoken]}', '#{session[:reftoken]}', '#{session[:city]}', '#{session[:state]}', '#{session[:country]}')")

        d = db.execute("SELECT * FROM runners WHERE runnerid=#{session[:sid]}")[0]
        session[:fullname]=d[1]
        session[:email]=d[3]
        session[:sid]=d[0]
        session[:uname]=d[2]
        session[:volume]=d[5]
        db.close
        erb :reg2
    rescue => e
        puts 'db error, retry:', $!, $@
        sleep 1
        retry if (retries += 1) < 3
    end
end

get '/gudsqap' do
    "Hi, #{session['name']}, got gudsqap: #{request['code']}"
end

get '/aero' do
    redirect 'http://aerobia.ru'
end


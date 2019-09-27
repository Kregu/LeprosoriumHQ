require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end


def init_db
  @db = SQLite3::Database.new 'leprosorium.db'
  @db.results_as_hash = true
end

before do
  init_db
end

configure do
  init_db
  @db.execute 'CREATE TABLE IF NOT EXISTS "Posts" (
                                                  "id"  INTEGER PRIMARY KEY AUTOINCREMENT,
                                                  "created_date"  TEXT,
                                                  "content" TEXT
                                                  )'

  init_db
  @db.execute 'CREATE TABLE IF NOT EXISTS "Comments" (
                                                  "id"  INTEGER PRIMARY KEY AUTOINCREMENT,
                                                  "created_date"  TEXT,
                                                  "content" TEXT,
                                                  "post_id" INTEGER
                                                  )'                                                  
end

get '/' do
  @results = @db.execute 'SELECT * FROM Posts ORDER BY ID DESC'
  erb :index
end

# get '/posts' do
#   erb 'Can you handle a <a href="/secure/place">secret</a>?'
# end

get '/new' do
  erb :new
end


get '/login/form' do
  erb :login_form
end

def content_empty? content
  content.length < 1
end

post '/new' do
  content = params[:content]

  if content_empty? content
    @error = 'Type post text'
    return erb :new
  end

  @db.execute 'INSERT INTO Posts (content, created_date) VALUES (?,datetime())', [content]

  redirect to ('/')
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end

get '/details/:post_id' do

  post_id = params[:post_id]
  results = @db.execute 'SELECT * FROM Posts WHERE ID = (?)', [post_id]
  @row = results[0]

  #select comments for the post
  @comments = @db.execute 'SELECT * FROM Comments WHERE post_id = ? ORDER BY id', [post_id]

  erb :details
end

post '/details/:post_id' do

  post_id = params[:post_id]
  content = params[:content]

  if content_empty? content
    @error = 'Type comment text'
    redirect to ('/details/' + post_id)
  end

  @db.execute 'INSERT INTO Comments (content, post_id, created_date) VALUES (?,?,datetime())', [content, post_id]

  redirect to ('/details/' + post_id)
end
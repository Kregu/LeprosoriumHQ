require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

# before '/secure/*' do
#   unless session[:identity]
#     session[:previous_url] = request.path
#     @error = 'Sorry, you need to be logged in to visit ' + request.path
#     halt erb(:login_form)
#   end
# end

set :database, "sqlite3:lephq.db"

class Post < ActiveRecord::Base
  has_many :comments
  validates :content, presence: true, length: { minimum: 2 }
end

class Comment < ActiveRecord::Base
  belongs_to :post
  validates :content, presence: true, length: { minimum: 2 }
end

get '/' do
  @post = Post.order 'created_at DESC'
  erb :index
end

get '/new' do
  erb :new
end


# get '/login/form' do
#   erb :login_form
# end

# def content_empty? content
#   content.length < 1
# end

post '/new' do
  @p = Post.new params[:post]

    if @p.save
    redirect to ('/')
  else
    @error = @p.errors.full_messages.first
    erb :new
  end
end

# post '/login/attempt' do
#   session[:identity] = params['username']
#   where_user_came_from = session[:previous_url] || '/'
#   redirect to where_user_came_from
# end

# get '/logout' do
#   session.delete(:identity)
#   erb "<div class='alert alert-message'>Logged out</div>"
# end

# get '/secure/place' do
#   erb 'This is a secret place that only <%=session[:identity]%> has access to!'
# end
get '/details/:post_id' do
  @post = Post.find params[:post_id]
  @comment = Post.find(params[:post_id]).comments
  erb :details
end


post '/details/:post_id' do
  post_id = params[:post_id]

  @c = Comment.new params[:comment]
  @c.post_id = post_id

  if @c.save
    redirect to ('/details/' + post_id)
  else
    @error = @c.errors.full_messages.first
    redirect to ('/details/' + post_id)
  end

end
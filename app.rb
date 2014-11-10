require 'sinatra'
require 'slim'
if development? || test?
  require 'dotenv'
  Dotenv.load
  require 'pry'
  require "better_errors"
end
require './models'

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

###############
### Helpers ###
###############
helpers do
  def message_params
    request_params = { author_ip: request.ip }
    params
      .merge(request_params)
      .reject do |k,v|
        k == :a_public_token.to_s || k == "splat" || k == "captures" || k == "redirect_to"
      end
  end
end

############################
### Routes & Controllers ###
############################
# home page
get "/" do
  slim :index, locals: {notice: ''}
end

# welcome page
get '/welcome' do
  slim :welcome
end

# create a new user
post "/" do
  user = User.new(email: params[:email])
  if user.save
    user.send_credentials(request)
    redirect to :welcome
  elsif params[:email].blank?
    slim :index, locals: {notice: 'Merci de renseigner votre email'}
  else
    slim :index, locals: {notice: 'Cet email est déjà enregistré'}
  end
end

# create a new message
post '/message/:a_public_token' do |token|
  user = User.find_by(token: token)
  if user.nil?
    403
  else
    message = user.referers
      .find_or_create_by(url: request.referer)
      .messages.new
    message.write_attributes(message_params)
    if message.save && params[:redirect_to]
      redirect params[:redirect_to]
    else
      redirect back
    end
  end
end

# index received messages
get '/message/:token/:private_token' do
  user = User.find_by(token: params[:token])
  if user.nil?
    404
  else
    if user.private_token == params[:private_token]
      @inboxes = user.referers
      slim :inbox
    else
      403
    end
  end
end

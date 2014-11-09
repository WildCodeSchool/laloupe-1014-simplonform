require 'sinatra'
if development? || test?
  require 'dotenv'
  Dotenv.load
  require 'pry'
  require "better_errors"
end
require 'slim'
require 'mongoid'
require 'pony'

configure do
  Mongoid.load!("./mongoid.yml")
  Mongoid.raise_not_found_error = false
  Pony.options = {
    :via => :smtp,
    :via_options => {
      :address => 'smtp.sendgrid.net',
      :port => '587',
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  }
end

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

#########################
### Models definition ###
#########################
class User
  include Mongoid::Document
  before_create :generate_tokens
  validates_uniqueness_of :email
  validates_presence_of :email
  has_many :referers

  field :email, type: String
  field :private_token, type: String
  field :token, type: String

  def send_credentials(request)
    posturl = "#{request.base_url}/message/#{self.token}"
    secreturl = "#{request.base_url}/message/#{self.token}/#{self.private_token}"
    Pony.mail(
      to: self.email,
      from: 'simbot@simplon-village.com',
      subject: 'Votre compte SimplonForm',
      body:
        "Bonjour et bienvenue chez SimplonForm\n\n
        Consultez la documentation pour connecter un formulaire à votre compte SimplonForm:\n
        https://github.com/SimplonVillage/simplonform#usage\n
        Vos identifiants:
        SF_POST_URL:" + posturl + "\n
        SF_SECRET_URL:" + secreturl + "\n\n
        Pour consulter vos messages reçus ourvir SF_SECRET_URL dans votre navigateur.
        Ce lien doit donc rester secret pour garantir la confidentialité de vos messages."
    )
  end

  private

  def generate_tokens
    self.private_token = SecureRandom.hex
    self.token = SecureRandom.uuid
    true
  end
end

class Referer
  include Mongoid::Document
  belongs_to :user
  embeds_many :messages

  field :url, type: String
end

class Message
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  before_save :set_timestamp
  embedded_in :referer

  field :received_at, type: DateTime
  field :author_ip, type: String

  def set_timestamp
    self.received_at = DateTime.now
  end

  def display_attr
    self.attributes.reject do |key, val|
      key == 'received_at' || key == '_id' || key == 'author_ip'
    end
  end
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

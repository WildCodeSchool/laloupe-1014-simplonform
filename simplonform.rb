require 'sinatra'
if development? || test?
  require 'dotenv'
  Dotenv.load
  require 'pry'
end
require 'slim'
require 'mongoid'
require 'pony'

configure do
  # mongodb
  Mongoid.load!("./mongoid.yml")
  Mongoid.raise_not_found_error = false
  # mailer
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

# models definition
class User
  include Mongoid::Document
  before_create :generate_tokens
  validates_uniqueness_of :email
  validates_presence_of :email
  has_many :messages

  field :email, type: String
  field :private_token, type: String
  field :token, type: String

  def generate_tokens
    self.private_token = SecureRandom.hex
    self.token = SecureRandom.uuid
    true
  end
end

class Message
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  before_save :set_timestamp
  belongs_to :user

  field :received_at, type: DateTime

  def set_timestamp
    self.received_at = DateTime.now
  end

	def display_attr
		self.attributes.reject{ |key, val| key == 'received_at' || key == '_id' || key == 'user_id' }
	end
end

# helpers
helpers do
  def message_params
    params.reject do |k,v|
      k == :a_public_token.to_s || k == "splat" || k == "captures" || k == "redirect_to"
    end
  end
end

# routes & controllers
get "/" do
  slim :index, locals: {notice: ''}
end

get '/welcome' do
	slim :welcome
end

post "/" do
  user = User.new(email: params[:email])
  if user.save
     posturl = "#{request.base_url}/message/#{user.token}"
     secreturl = "#{request.base_url}/message/#{user.token}/#{user.private_token}"
    Pony.mail(
      to: user.email,
      from: 'simbot@simplon-village.com',
      subject: 'Votre compte SimplonForm',
      body: "Coucou et bienvenue chez nous\n\n
      Vous pouvez envoyer des requêtes POST à cette adresse :" + posturl + "\n
      Vous pouvez consulter vos messages à cette adresse :" + secreturl
    )
    redirect to :welcome
  else
    slim :index, locals: {notice: 'Cet email est déjà enregistré'}
  end
end

post '/message/:a_public_token' do |token|
  recipient = User.find_by(token: token)
  if recipient.nil?
    403
  else
    message = recipient.messages.new
    message.write_attributes message_params
    if message.save && params[:redirect_to]
      redirect params[:redirect_to]
    else
      redirect back
    end
  end
end

get '/message/:token/:private_token' do
  recipient = User.find_by(token: params[:token])
  if recipient.nil?
    404
  else
    if recipient.private_token == params[:private_token]
      @messages = recipient.messages.sort{|x,y| y.received_at <=> x.received_at } #TODO - refactor
      slim :inbox
    else
      403
    end
  end
end

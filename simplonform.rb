require 'sinatra'
if development?
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
end

# helpers
helpers do
  def message_params
    params.reject do |k,v|
      k == :a_public_token.to_s || k == "splat" || k == "captures"
    end
  end
end

# routes & controllers
get "/" do
  slim :index, locals: {notice: ''}
end

post "/" do
  user = User.new(email: params[:email])
  if user.save
    Pony.mail(
      to: user.email,
      from: 'simbot@simplon-village.com',
      subject: 'Votre compte SimplonForm',
      body: 'Coucou et bienvenue chez nous'
    )
    slim :welcome
  else
    slim :index, locals: {notice: 'Cet email est déjà enregistré'}
  end
end

post '/message/:a_public_token' do |token|
  recipient = User.find_by(token: token)
  if recipient.nil?
    403
  else
    message = Message.new
    message.write_attributes message_params
    message.save
    200
  end
end

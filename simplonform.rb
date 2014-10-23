require 'sinatra'
require 'slim'
require 'mongoid'

configure do
  Mongoid.load!("./mongoid.yml")
end

# models definition
class User
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  before_create :generate_tokens

  field :email, type: String
  field :private_token, type: String
  field :token, type: String

  def generate_tokens 
    self.private_token = SecureRandom.hex
    self.token = SecureRandom.uuid
  end
end
class Message
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
end

# routes & controllers
get "/" do
  slim :index
end

post "/" do
  User.create(email: params[:toto])
  # envoyer un email à l'utilisateur avec ses 2 tokens
  slim :welcome
end

post '/message' do
  200
end

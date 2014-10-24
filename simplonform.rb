require 'sinatra'
require 'slim'
require 'mongoid'
require 'pry' if development?

configure do
  Mongoid.load!("./mongoid.yml")
  Mongoid.raise_not_found_error = false
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

# routes & controllers
get "/" do
  slim :index
end

post "/" do
  user = User.new(email: params[:email])
  if user.save
    slim :welcome
  else
    slim :index
  end
end

post '/message/:a_public_token' do
  recipient = User.find_by(token: params[:a_public_token])
  if recipient.nil?
    403
  else
    message = Message.new
    message.
      write_attributes(params.reject{|k,v| k == :a_public_token.to_s || k == "splat" || k == "captures"})
    message.save
    200
  end
end

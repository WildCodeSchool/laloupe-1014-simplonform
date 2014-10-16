require 'sinatra'
require 'slim'
require 'mongoid'
require 'pry'

configure do
  Mongoid.load!("./mongoid.yml")
end

# models definition
class User
  include Mongoid::Document
  before_create :generate_tokens

  field :email, type: String
  field :private_token, type: String
  field :token, type: String

  def generate_tokens 
    self.private_token = SecureRandom.hex
    self.token = SecureRandom.uuid
  end
end

# routes & controllers
post '/form' do
  200
end

get "/" do
  slim :index
end

post "/" do
  User.create(email: params[:email])
end

require 'sinatra'
require 'slim'
require 'mongoid'
require 'pry'

configure do
	Mongoid.load!("./mongoid.yml")
end

class User
	include Mongoid::Document

	field :email, type: String
end

post '/form' do
	200
end

get "/" do
	slim :index
end

post "/" do
	User.create(email: params[:email])
end



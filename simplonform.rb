require 'sinatra'
require 'slim'
require 'pry'
require 'sinatra/activerecord'
require 'tilt'
set :database, {adapter: "sqlite3", database: "simplonform.sqlite3"}

class Form < ActiveRecord::Base
	validates_presence_of :email
end
post '/form/:token' do
	200
end

get "/" do
	slim :index
	end

post "/" do
	binding.pry
end


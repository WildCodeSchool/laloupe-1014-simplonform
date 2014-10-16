ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative 'simplonform.rb'

include Rack::Test::Methods

def app
  Sinatra::Application
end

describe "The setup" do

  it "should display an email field" do 
    get '/'
    assert last_response.body.include?('email')
  end

  it "should create a user" do
    User.delete_all
    post "/", params = {email: "yolo@yolo.com"}
    assert last_response.ok?
    assert_equal 1, User.count
  end

  it "should generate 2 tokens" do
    User.delete_all
  	post "/", params = {email: "yolo@yolo.com"}
    assert_equal 36, User.last.token.length #uuid
    assert_equal 32, User.last.private_token.length #hex
  end

  it "should redirect to a welcome page" do
    User.delete_all
    post "/", params = {email: "yolo@yolo.com"}
    assert last_response.body.include?('Welcome')
  end

  # it "should validate that the email is valid"

  # it "should send an email to the new user"
end

describe "Simplon Form" do

  it "should handle the form" do
    post '/form', params={name: "mathieu", mail: "carbonel@gmail.com"}
    assert last_response.ok?
  end

  # it "should create a new Form dynamically"
end

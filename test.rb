ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative 'simplonform.rb'
 
include Rack::Test::Methods
 
def app
  Sinatra::Application
end

describe "simplonform" do 
  it "should handle the form" do
    post '/form', params={name: "mathieu", mail: "carbonel@gmail.com", tel: "0689347777"}
    assert last_response.ok?
  end

  it "should display an email field" do 
    get '/'
    assert last_response.body.include? ('email')
  end

  it "should create a user" do
  	users_count = User.count
  	post "/", params={email: "yolo@yolo.com"}
  	assert last_response.ok?
  	assert_equal users_count + 1, User.count
  end
end

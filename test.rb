ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative 'simplonform.rb'

include Rack::Test::Methods
I18n.enforce_available_locales = false

def app
  Sinatra::Application
end

describe "When a user connect to the website" do
  it "should display an email field" do
    get '/'
    assert last_response.body.include?('email')
  end
end

describe "When a user submit its email" do
  email = "yolo@yolo.com"
  it "should successfully redirect to a welcome page" do
    User.delete_all
    post "/", params = {email: email}
    assert last_response.ok?
    assert last_response.body.include?('Welcome')
  end
  it "should create a new user" do
    User.delete_all
    post "/", params = {email: email}
    assert_equal 1, User.count
    assert_equal email, User.last.email
  end
  it "should generate 2 tokens" do
    User.delete_all
    post "/", params = {email: email}
    assert_equal 36, User.last.token.length #uuid
    assert_equal 32, User.last.private_token.length #hex
  end
  it "should not create a user if the email exists in the database" do
    User.delete_all
    User.create(email: email)
    post "/", params = {email: email}
    assert_equal 1, User.count
  end
  # it "should send an email to the new user"
end

describe "When a user submit wrong informations" do
  it "should not create a user if there is no email" do
    User.delete_all
    post '/', params = {name: "JD"}
    assert_equal 0, User.count
  end
  # it "should not create a user with an invalid email"
end

describe "When a form post a message" do
  User.delete_all
  user = User.create(email: "formowner@form.com")
  token = user.token
  message = {name: 'Jean Dupont', email: 'jd@gmail.com', content: 'Bonjour !'}
  it "should create a new Message" do
    skip
    Message.delete_all
    post "/message/#{token}", params = message
    assert_equal 1, Message.count
  end
  it "should store all the attributes posted into the datatbase" do
    skip
    Message.delete_all
    post "/message/#{token}", params = message
    assert_equal message[:name],  Message.last.name
    assert_equal message[:email], Message.last.email
    assert_equal message[:content], Message.last.content
  end
end

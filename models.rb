require 'mongoid'
require 'pony'

configure do
  Mongoid.load!("./mongoid.yml")
  Mongoid.raise_not_found_error = false
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

#########################
### Models definition ###
#########################
class User
  include Mongoid::Document
  before_create :generate_tokens
  validates_uniqueness_of :email
  validates_presence_of :email
  has_many :referers

  field :email, type: String
  field :private_token, type: String
  field :token, type: String

  def send_credentials(request)
    posturl = "#{request.base_url}/message/#{self.token}"
    secreturl = "#{request.base_url}/message/#{self.token}/#{self.private_token}"
    Pony.mail(
      to: self.email,
      from: 'simbot@simplon-village.com',
      subject: 'Votre compte SimplonForm',
      body:
        "Bonjour et bienvenue chez SimplonForm\n\n
        Consultez la documentation pour connecter un formulaire à votre compte SimplonForm:\n
        https://github.com/SimplonVillage/simplonform#usage\n
        Vos identifiants:
        SF_POST_URL:" + posturl + "\n
        SF_SECRET_URL:" + secreturl + "\n\n
        Pour consulter vos messages reçus ourvir SF_SECRET_URL dans votre navigateur.
        Ce lien doit donc rester secret pour garantir la confidentialité de vos messages."
    )
  end

  private

  def generate_tokens
    self.private_token = SecureRandom.hex
    self.token = SecureRandom.uuid
    true
  end
end

class Referer
  include Mongoid::Document
  belongs_to :user
  embeds_many :messages

  field :url, type: String
end

class Message
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  before_save :set_timestamp
  embedded_in :referer

  field :received_at, type: DateTime
  field :author_ip, type: String

  def set_timestamp
    self.received_at = DateTime.now
  end

  def display_attr
    self.attributes.reject do |key, val|
      key == 'received_at' || key == '_id' || key == 'author_ip'
    end
  end
end


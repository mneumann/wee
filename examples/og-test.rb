# -----------------------------------------
# The datamodel
# -----------------------------------------

require 'rubygems'
require_gem 'og', '>= 0.21.0'

class Customer < Og::Entity
  property :address, String, :sql => 'VARCHAR(100) NOT NULL'
  property :email, String, :sql => 'VARCHAR(50) NOT NULL'
  property :password, String, :sql => 'VARCHAR(10) NOT NULL', :ui => :password

  property :birth_date, Date, :label => 'Date of Birth'
  property :active, TrueClass

  validate_value :address
  validate_value :email
  validate_value :password
end

# -----------------------------------------
# The Wee part
# -----------------------------------------

require 'wee'

class CustomerList < Wee::Component
  def initialize
    super()
    add_decoration(Wee::PageDecoration.new("Hello World"))

    add_child(@customer_list = OgScaffolder.new(Customer))
    add_child(@customer_list2 = OgScaffolder.new(Customer))
  end

  def render
    r.render @customer_list
    r.render @customer_list2
  end
end

if __FILE__ == $0
  require 'wee/adaptors/webrick' 
  require 'wee/utils'
  require 'wee/databases/og'

  DB_CONFIG = {
    :address => "localhost",
    :name => "mneumann",
    :store => "psql",
    :user => "mneumann",
    :password => "",
    #:destroy => true,
    :connection_count => 10 
  }

  app = Wee::Utils.app_for(CustomerList, :application => OgApplication, :session => OgSession)
  app.db = Og.setup(DB_CONFIG)
  Wee::WEBrickAdaptor.register('/app' => app).start
end

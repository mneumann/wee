# -----------------------------------------
# The datamodel
# -----------------------------------------

require 'og'

class Customer
  prop_accessor :address, String, :sql => 'VARCHAR(100) NOT NULL'
  prop_accessor :email, String, :sql => 'VARCHAR(50) NOT NULL'
  prop_accessor :password, String, :sql => 'VARCHAR(10) NOT NULL'
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
    :database => "mneumann",
    :backend => "psql",
    :user => "mneumann",
    :password => "",
    :connection_count => 10 
  }

  app = Wee::Utils.app_for(CustomerList, :application => OgApplication, :session => OgSession)
  app.db = Og::Database.new(DB_CONFIG)
  Wee::WEBrickAdaptor.register('/app' => app).start
end

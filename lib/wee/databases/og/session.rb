class OgSession < Wee::Session
  def awake
    application.db.get_connection
  end

  def sleep
    application.db.put_connection
  end
end

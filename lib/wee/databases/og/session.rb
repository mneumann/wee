class OgSession < Wee::Session
  def awake
    application.db.get_store
  end

  def sleep
    application.db.put_store
  end
end

class ValidatorDefault

  def self.pattern
    /.+/
  end


  def self.pattern_format
    '< any characters >'
  end


  def initialize(*args)
  end


  def account_is_open!
    true
  end


  def latest_expiration
    Time.zone.now
  end

end
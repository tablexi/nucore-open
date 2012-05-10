module PowerRelay
  def self.included(base)
    ## validations
    base.validates_presence_of :ip, :port, :username, :password
  end

  ## instance methods
  def control_mechanism
    'relay'
  end
end

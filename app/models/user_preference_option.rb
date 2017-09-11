class UserPreferenceOption
    def initialize(user)
    @user = user
  end

  def name
    raise NotImplementedError
  end

  def visible_to_user?
    raise NotImplementedError
  end

  def options_for_user
    raise NotImplementedError
  end

  def default_value
    raise NotImplementedError
  end
end

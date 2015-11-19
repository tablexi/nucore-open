class UserPresenter < SimpleDelegator

  delegate :global, to: :user_roles, prefix: true

  def self.wrap(users)
    users.map { |user| new(user) }
  end

  def global_role_list
    global_roles.join(", ")
  end

  def name_last_comma_first
    "#{last_name}, #{first_name}"
  end

  private

  def global_roles
    user_roles_global.pluck(:role)
  end

end

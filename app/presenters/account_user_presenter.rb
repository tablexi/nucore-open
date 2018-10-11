
class AccountUserPresenter < SimpleDelegator
  def self.localized_role(role)
    I18n.t(role.downcase.parameterize.underscore, scope: "accounts.role") # Move the en.yml location to be more generic than `member_table`
  end

  def self.selectable_user_roles(granting_user = nil, facility = nil)
    # Nothing other than the collection uses `selectable_user_roles`, so it could even be pulled up into this class
    AccountUser.selectable_user_roles(granting_user, facility).map {  |role| [localized_role(role), role] }
  end

  def localized_role
    self.class.localized_role(user_role)
  end
end

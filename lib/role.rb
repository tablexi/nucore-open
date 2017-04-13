# There are many roles that can be assigned to users.
# Mix this module into the +User+ class to include
# convenience methods for testing the role status of users.
module Role

  # Creates methods #administrator?, #facility_staff?, etc.
  # Each returns true if #user_roles has the role for any facility.
  UserRole.global_roles.each do |role|
    define_method(role.gsub(/\s/, "_").downcase + "?") do
      roles = user_roles.collect(&:role)
      roles.include?(role)
    end
  end

  # Creates methods #administrator_of?, #facility_staff_of?, etc.
  # Each takes a +Facility+ as an argument.
  # Each returns true if #user_roles has the role for the given facility.
  UserRole.facility_roles.each do |role|
    define_method(role.gsub(/\s/, "_").downcase + "_of?") do |facility|
      user_roles.find { |r| r.facility == facility && r.role == role }.present?
    end
  end

  # Returns relation of facilities for which this user is staff, a director, or an admin
  def operable_facilities
    if try(:administrator?)
      Facility.sorted
    else
      facilities.sorted.where(user_roles: { role: UserRole.facility_roles})
    end
  end

  # Returns relation of facilities for which this user is a director or admin
  def manageable_facilities
    if try(:administrator?) || try(:billing_administrator?)
      Facility.sorted
    else
      facilities.sorted.where(user_roles: { role: UserRole.facility_management_roles })
    end
  end

  def operator_of?(facility)
    return false if facility.blank?
    manager_of?(facility) || facility_staff_of?(facility) || facility_senior_staff_of?(facility)
  end

  def manager_of?(facility)
    return false if facility.blank?
    facility_director_of?(facility) || facility_administrator_of?(facility) || administrator?
  end

  def can_override_restrictions?(product)
    operator_of? product.facility
  end

  def cannot_override_restrictions?(product)
    !operator_of?(product.facility)
  end

  #
  # Account management roles
  #

  AccountUser.user_roles.each do |role|
    #
    # Creates methods #purchaser?, #owner?, etc.
    # Each returns true if #account_users has the user_role for any account.
    define_method(role.gsub(/\s/, "_").downcase + "?") do
      roles = account_users.collect(&:user_role)
      roles.include?(role)
    end

    #
    # Creates methods #purchaser_of?, #owner_of?, etc.
    # Each takes an +Account+ as an argument.
    # Each returns true if #account_users has the user_role for the given account.
    define_method(role.gsub(/\s/, "_").downcase + "_of?") do |account|
      account_users.find { |au| au.account == account && au.user_role == role }.present?
    end
  end

  def account_administrator?
    owner? || business_administrator?
  end

  def account_administrator_of?(account)
    owner_of?(account) || business_administrator_of?(account)
  end

  # where is this used? do we need it?
  def name
    to_s
  end

end

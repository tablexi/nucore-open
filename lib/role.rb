#
# There are many roles that can be assigned to users.
# Mix this module into the +User+ class to include
# convenience methods for testing the role status of users.
module Role

  #
  # Facility management roles
  #

  (UserRole.administrator + UserRole.billing_administrator + UserRole.facility_roles).each do |role|
    #
    # Creates methods #administrator?, #facility_staff?, etc.
    # Each returns true if #user_roles has the role for any facility.
    define_method(role.gsub(/\s/, '_').downcase + '?') do
      roles=user_roles.collect(&:role)
      roles.include?(role)
    end

    #
    # Creates methods #administrator_of?, #facility_staff_of?, etc.
    # Each takes a +Facility+ as an argument.
    # Each returns true if #user_roles has the role for the given facility.
    define_method(role.gsub(/\s/, '_').downcase + '_of?') do |facility|
      is=false
      user_roles.each {|ur| is=true and break if ur.facility == facility && ur.role == role }
      is
    end

    # Creates method #operable_facilities
    # returns relation of facilities for which this user is staff, a director, or an admin
    define_method(:operable_facilities) do
      if self.try(:administrator?)
        Facility.scoped
      else
        self.facilities.where("user_roles.role IN(?)", UserRole.facility_roles)
      end
    end
      
    
    #
    # Creates method #manageable_facilities
    # returns relation of facilities for which this user is a director or admin
    define_method(:manageable_facilities) do
      if self.try(:administrator?) or self.try(:billing_administrator?)
        Facility.scoped
      else
        facilities.where("user_roles.role IN (?)", UserRole.facility_management_roles)
      end
    end
  end


  def operator?
    manager? || facility_staff?
  end


  def manager?
    facility_director? || facility_administrator?
  end


  def operator_of?(facility)
    manager_of?(facility) || facility_staff_of?(facility)
  end


  def manager_of?(facility)
    facility_director_of?(facility) || facility_administrator_of?(facility) || administrator?
  end

  def can_override_restrictions?(product)
    operator_of? product.facility
  end

  #
  # Account management roles
  #

  AccountUser.user_roles.each do |role|
    #
    # Creates methods #purchaser?, #owner?, etc.
    # Each returns true if #account_users has the user_role for any account.
    define_method(role.gsub(/\s/, '_').downcase + '?') do
      roles=account_users.collect(&:user_role)
      roles.include?(role)
    end

    #
    # Creates methods #purchaser_of?, #owner_of?, etc.
    # Each takes an +Account+ as an argument.
    # Each returns true if #account_users has the user_role for the given account.
    define_method(role.gsub(/\s/, '_').downcase + '_of?') do |account|
      is=false
      account_users.each {|au| is=true and break if au.account == account && au.user_role == role }
      is
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

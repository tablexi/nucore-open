class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :facility


  ADMINISTRATOR='Administrator'
  FACILITY_DIRECTOR='Facility Director'
  FACILITY_ADMINISTRATOR='Facility Administrator'
  FACILITY_STAFF='Facility Staff'


  def self.administrator
    [ ADMINISTRATOR ]
  end


  def self.facility_roles
    [ FACILITY_DIRECTOR, FACILITY_ADMINISTRATOR, FACILITY_STAFF ]
  end


  def self.facility_management_roles
    facility_roles - [ FACILITY_STAFF ]
  end

  
  #
  # Assigns +role+ to +user+ for +facility+
  # [_user_]
  #   the user you want to grant permissions to
  # [_role_]
  #   one of this class' constants
  # [_facility_]
  #   the facility that you want to grant permissions on.
  #   Leave nil when creating administrators
  def self.grant(user, role, facility=nil)
    create!(:user => user, :role => role, :facility => facility)
  end


  validates_presence_of :user_id
  validates_inclusion_of :role, :in => (administrator + facility_roles), :message => 'is not a valid value'
end

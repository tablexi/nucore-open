class Ability
  include CanCan::Ability

  #
  # [_user_]
  #   Who is being un/authorized
  # [_resource_]
  #   A model +user+ is authorized against
  # [_controller_]
  #   The controller whose authorization request is being handled. Used to provide
  #   a context for the sticky situation that is multiple controllers managing one
  #   one model each with their own authorization rules.
  def initialize(user, resource, controller)
    return unless user

    if user.administrator?
      can :manage, :all
      return
    end
    
    can :list, Facility if user.facilities.size > 0 and controller.is_a?(FacilitiesController)
    
    return unless resource

    if user.billing_administrator?
      
      # can manage orders / order_details / reservations
      can :manage, [Order, OrderDetail, Reservation]
      
      # can manage all journals
      can :manage, Journal

      # can manage all accounts
      can :manage, Account

      # can list transactions for a facility
      can [:transactions, :manage_billing], Facility
    end

    if resource.is_a?(Facility)
      can :complete, Surveyor
     
      if user.operator_of?(resource)
        can :manage, [
          AccountPriceGroupMember, OrderDetail, Order, Reservation,
          UserPriceGroupMember, ProductUser
        ]

        can [:index, :view_details, :schedule, :show], [Product]

        can [:upload, :uploader_create, :destroy], StoredFile do |fileupload|
          fileupload.file_type == 'sample_result'
        end

        can :manage, User if controller.is_a?(UsersController)

        cannot :show_problems, Order
        can [ :schedule, :agenda, :list, :show ], Facility
        can :act_as, Facility

        can :index, [ BundleProduct, PricePolicy, InstrumentPricePolicy, ItemPricePolicy, ScheduleRule, ServicePricePolicy, ProductAccessory, ProductAccessGroup ]
        can [:instrument_status, :instrument_statuses, :switch], Instrument
        can :edit, [PriceGroupProduct]
      end

      if user.facility_director_of?(resource)
        can [ :activate, :deactivate ], Surveyor
      end

      if user.manager_of?(resource)
        can :manage, [
          AccountUser, FacilityAccount, Journal,
          Statement, StoredFile, PricePolicy, InstrumentPricePolicy,
          ItemPricePolicy, OrderStatus, PriceGroup, ReportsController,
          ScheduleRule, ServicePricePolicy, PriceGroupProduct, ProductAccessGroup,
          ProductAccessory, Product, BundleProduct
        ]

        can :manage, User if controller.is_a?(FacilityUsersController)

        # A facility admin can manage an account if it has no facility (i.e. it's a chart string) or the account
        # is attached to the current facility.
        can :manage, Account do |account|
          account.facility.nil? || account.facility == resource
        end

        can :show_problems, Order
        can [:update, :manage], Facility
      end      
      
      # Facility senior staff is based off of staff, but has a few more abilities
      if in_role?(user, resource, UserRole::FACILITY_SENIOR_STAFF)
        can :manage, [ScheduleRule, ProductUser, ProductAccessGroup, StoredFile, ProductAccessory]
        
        # they can get to reports controller, but they're not allowed to export all
        can :manage, ReportsController
        cannot :export_all, ReportsController
      end

    elsif resource.is_a?(Account)
      if user.account_administrator_of?(resource)
        can :manage, Account
        can :manage, AccountUser
        can [:show, :suspend, :unsuspend, :user_search, :user_accounts, :statements, :show_statement, :index], Statement
      end

    elsif resource.is_a?(Reservation)
      # TODO Add :accessory hash back in to hide hidden accessories from non-admin users
      # See task #55479
      can :read, ProductAccessory #, :accessory => { :is_hidden => false }
      if user.operator_of?(resource.instrument.facility)
        can :read, ProductAccessory
        can :manage, Reservation 
      end
      can :start_stop, Reservation if resource.order_detail.order.user_id == user.id
    end

  end

  def in_role?(user, facility, *roles)
    # facility_user_roles returns full objects; we just want the names
    facility_roles = user.facility_user_roles(facility).map(&:role)
    # do the roles the user is part of match any of the potential roles
    (facility_roles & roles).any?
  end

end

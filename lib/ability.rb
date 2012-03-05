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

    if resource.is_a?(Facility)

      can :complete, Surveyor
      
      
      if user.operator_of?(resource)
        can :manage, [
          AccountPriceGroupMember, Service, BundleProduct,
          Bundle, OrderDetail, Order, Reservation, Instrument,
          Item, ProductUser, Product, UserPriceGroupMember
        ]
        
        can :manage, User if controller.is_a?(UsersController)

        cannot :show_problems, Order
        can [ :schedule, :agenda, :list ], Facility
        can :index, [ InstrumentPricePolicy, ItemPricePolicy, ScheduleRule, ServicePricePolicy ]
      end

      if user.facility_director_of?(resource)
        can [ :activate, :deactivate ], Surveyor
      end

      if user.manager_of?(resource)
        can :manage, [
          AccountUser, Account, FacilityAccount, Journal,
          Statement, FileUpload, InstrumentPricePolicy,
          ItemPricePolicy, OrderStatus, PriceGroup, ReportsController,
          ScheduleRule, ServicePricePolicy, PriceGroupProduct, ProductAccessGroup
        ]

        can :manage, User if controller.is_a?(FacilityUsersController)

        can [ :update, :manage ], Facility
        can :show_problems, Order
      end
      
      

    elsif resource.is_a?(Account)

      if user.account_administrator_of?(resource)
        can :manage, Account
        can :manage, AccountUser
        can [:show, :suspend, :unsuspend, :user_search, :user_accounts, :statements, :show_statement, :index], Statement
      end

    end

  end

end
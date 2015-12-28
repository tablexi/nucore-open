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
      if resource.is_a?(PriceGroup)
        can :manage, UserPriceGroupMember if resource.admin_editable?
        can :manage, AccountPriceGroupMember
      else
        can :manage, :all
        unless user.billing_administrator?
          cannot [:manage_accounts, :manage_billing, :manage_users], Facility.cross_facility
        end
        unless user.account_manager?
          cannot :manage, User unless resource.is_a?(Facility) && resource.single_facility?
        end
      end
      return
    end

    if resource.is_a?(PriceGroup)
      if !resource.global? && user.manager_of?(resource.facility)
        can :manage, [AccountPriceGroupMember, UserPriceGroupMember]
      end

      if user_has_facility_role?(user) && editable_global_group?(resource)
        can :read, UserPriceGroupMember
      end
    end

    can :list, Facility if user.facilities.size > 0 and controller.is_a?(FacilitiesController)
    can :read, Notification if user.notifications.active.any?

    if user.account_manager?
      can [:manage_accounts, :manage_users], Facility.cross_facility

      if resource.blank? || resource == Facility.cross_facility
        can :manage, [Account, AccountUser, User]
      end

      cannot [:suspend, :unsuspend], Account
    end

    if user.billing_administrator?
      can :manage, [Account, Journal, Order, OrderDetail, Reservation]
      cannot :administer, [Order, OrderDetail, Reservation]
      can :manage_billing, Facility.cross_facility
      can [:disputed_orders, :movable_transactions, :transactions], Facility do |facility|
        facility.cross_facility?
      end
    end

    return unless resource

    if resource.is_a?(OrderDetail)
      order_details_ability(user, resource)
    end

    if resource.is_a?(Facility)
      can :complete, ExternalService
      can :create, TrainingRequest

      if user.operator_of?(resource)
        can :manage, [
          AccountPriceGroupMember,
          OrderDetail,
          ProductUser,
          TrainingRequest,
          UserPriceGroupMember,
        ]

        can :read, Notification

        can [
          :administer,
          :assign_price_policies_to_problem_orders,
          :batch_update,
          :create,
          :edit,
          :edit_admin,
          :index,
          :show,
          :tab_counts,
          :timeline,
          :update,
          :update_admin,
        ], Reservation

        can(:destroy, Reservation) { |r| r.admin? }

        can [
          :administer,
          :assign_price_policies_to_problem_orders,
          :batch_update,
          :create,
          :index,
          :order_in_past,
          :send_receipt,
          :show,
          :tab_counts,
          :update,
        ], Order

        can [:administer, :index, :view_details, :schedule, :show], Product

        can [:upload, :uploader_create, :destroy], StoredFile do |fileupload|
          fileupload.file_type == 'sample_result'
        end

        can [:administer, :switch_to], User
        can :manage, User if controller.is_a?(UsersController)

        can [ :list, :show ], Facility
        can :act_as, Facility

        can :index, [ BundleProduct, PricePolicy, InstrumentPricePolicy, ItemPricePolicy, ScheduleRule, ServicePricePolicy, ProductAccessory, ProductAccessGroup ]
        can [:instrument_status, :instrument_statuses, :switch], Instrument
        can :edit, [PriceGroupProduct]
      end

      if user.manager_of?(resource)
        can :manage, [
          AccountUser, Facility, FacilityAccount, Journal,
          Statement, StoredFile, PricePolicy, InstrumentPricePolicy,
          ItemPricePolicy, OrderStatus, PriceGroup, ReportsController,
          ScheduleRule, ServicePricePolicy, PriceGroupProduct, ProductAccessGroup,
          ProductAccessory, Product, BundleProduct, TrainingRequest
        ]

        can :manage, User if controller.is_a?(FacilityUsersController)
        cannot [:manage_accounts, :manage_billing, :manage_users], Facility.cross_facility

        # A facility admin can manage an account if it has no facility (i.e. it's a chart string) or the account
        # is attached to the current facility.
        can :manage, Account do |account|
          account.facility.nil? || account.facility == resource
        end

        can [:disputed, :show_problems], [Order, Reservation]
        can [:activate, :deactivate], ExternalService
      end

      # Facility senior staff is based off of staff, but has a few more abilities
      if in_role?(user, resource, UserRole::FACILITY_SENIOR_STAFF)
        can :manage, [ScheduleRule, ProductUser, ProductAccessGroup, StoredFile, ProductAccessory, TrainingRequest]

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
      if user.operator_of?(resource.product.facility)
        can :read, ProductAccessory
        can :manage, Reservation
      end
      can :start_stop, Reservation if resource.order.try(:user_id) == user.id

    elsif resource.is_a?(TrainingRequest)
      can :create, TrainingRequest

      if user.facility_director_of?(resource.product.facility) ||
          in_role?(user, resource.product.facility, UserRole::FACILITY_SENIOR_STAFF)
        can :manage, TrainingRequest
      end
    end
  end

  def in_role?(user, facility, *roles)
    # facility_user_roles returns full objects; we just want the names
    facility_roles = user.facility_user_roles(facility).map(&:role)
    # do the roles the user is part of match any of the potential roles
    (facility_roles & roles).any?
  end

private

  def order_details_ability(user, resource)
    can %i(add_accessories sample_results show template_results), OrderDetail, order: { user_id: user.id }
    can :manage, OrderDetail, :order => { :facility_id => resource.order.facility_id } if user.operator_of?(resource.facility)
    can :show, OrderDetail, :account => { :id => resource.account_id } if user.account_administrator_of?(resource.account)
  end

  def user_has_facility_role?(user)
    (user.user_roles.map(&:role) & UserRole.facility_roles).any?
  end

  def editable_global_group?(resource)
    resource.global? && resource.admin_editable?
  end
end

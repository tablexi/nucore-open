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
    can :read, Notification if user.operator? || user.administrator?

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

        can [
          :assign_price_policies_to_problem_orders,
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

        can [
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
        can [ :activate, :deactivate ], ExternalService
        can :disputed, [Order, Reservation]
        can :manage, TrainingRequest
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

        # A facility admin can manage an account if it has no facility (i.e. it's a chart string) or the account
        # is attached to the current facility.
        can :manage, Account do |account|
          account.facility.nil? || account.facility == resource
        end

        can :show_problems, [Order, Reservation]
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

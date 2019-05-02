# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
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
  def initialize(user, resource, controller = nil)
    return unless user

    if user.administrator?
      if resource.is_a?(PriceGroup)
        can :manage, UserPriceGroupMember if resource.admin_editable?
        can :manage, AccountPriceGroupMember
      else
        can :manage, :all
        unless user.billing_administrator?
          cannot [:manage_accounts, :manage_billing], Facility.cross_facility
        end
        unless user.account_manager?
          cannot :manage, User unless resource.is_a?(Facility)
          if SettingsHelper.feature_off?(:create_users)
            cannot([:edit, :update], User)
          end
        end
      end

      cannot(:switch_to, User) { |target_user| !target_user.active? }
      ability_extender.extend(user, resource)
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

    can :list, Facility if user.facilities.size > 0 && controller.is_a?(FacilitiesController)
    can :read, Notification if user.notifications.active.any?

    if user.account_manager?
      can [:manage_accounts, :manage_users], Facility.cross_facility

      if resource.blank? || resource == Facility.cross_facility
        can :manage, AccountUser
        can [:create, :read, :administer, :accounts, :new_external, :search], User
        can [:create, :read, :update, :suspend, :unsuspend], Account
        if SettingsHelper.feature_off?(:create_users)
          cannot([:create, :update], User)
        end
      end
    end

    if user.billing_administrator?
      can :manage, [Account, Journal, OrderDetail]
      can [:send_receipt, :show], Order
      if resource == Facility.cross_facility
        can [:accounts, :index, :orders, :show, :administer], User
      end
      can :manage_users, Facility.cross_facility if SettingsHelper.feature_on?(:billing_administrator_users_tab)
      can :manage_billing, Facility.cross_facility
      can [:disputed_orders, :movable_transactions, :transactions], Facility, &:cross_facility?
    end

    return unless resource

    order_details_ability(user, resource) if resource.is_a?(OrderDetail)

    if resource.is_a?(Facility)
      can :manage, [Journal, Statement] if user.billing_administrator?
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
          :cancel,
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

        if user.manager_of?(resource) || user.facility_senior_staff_of?(resource)
          can :bring_online, OfflineReservation
        else
          cannot :manage, OfflineReservation
        end

        can(:destroy, Reservation, &:admin?)

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

        can [:index], StoredFile
        can [:upload_sample_results, :destroy], StoredFile do |fileupload|
          fileupload.file_type == "sample_result"
        end

        can [:administer], User
        can(:switch_to, User, &:active?)

        if controller.is_a?(UsersController)
          can [:read, :create, :search, :access_list, :access_list_approvals, :new_external, :orders, :accounts], User
        end

        can :user_search_results, User if controller.is_a?(SearchController)

        can [:list, :dashboard, :show], Facility
        can :act_as, Facility
        can :index, [BundleProduct, PricePolicy, InstrumentPricePolicy, ItemPricePolicy, ScheduleRule, ServicePricePolicy, ProductAccessory, ProductAccessGroup]
        can [:instrument_status, :instrument_statuses, :switch], Instrument
        can :edit, [PriceGroupProduct]
      end

      if user.manager_of?(resource)
        can :manage, [
          AccountUser,
          BundleProduct,
          Facility,
          FacilityAccount,
          InstrumentPricePolicy,
          ItemPricePolicy,
          Journal,
          OrderImport,
          OrderStatus,
          PriceGroup,
          PriceGroupProduct,
          PricePolicy,
          Product,
          ProductAccessGroup,
          ProductAccessory,
          Reports::ReportsController,
          ScheduleRule,
          ServicePricePolicy,
          Statement,
          StoredFile,
          TrainingRequest,
        ]

        can :manage, User if controller.is_a?(FacilityUsersController)
        cannot([:edit, :update], User)
        cannot [:manage_accounts, :manage_billing, :manage_users], Facility.cross_facility

        # A facility admin can manage an account if it is global (i.e. it's a chart string) or the account
        # is attached to the current facility.
        can :manage, Account do |account|
          account.global? || account.account_facility_joins.any? { |af| af.facility_id == resource.id }
        end

        can [:show_problems], [Order, Reservation]
        can [:activate, :deactivate], ExternalService
      end

      # Facility senior staff is based off of staff, but has a few more abilities
      if in_role?(user, resource, UserRole::FACILITY_SENIOR_STAFF)
        can :manage, [
          ProductAccessGroup,
          ProductAccessory,
          ProductUser,
          ScheduleRule,
          StoredFile,
          TrainingRequest,
        ]

        # they can get to reports controller, but they're not allowed to export all
        can :manage, Reports::ReportsController
        cannot :export_all, Reports::ReportsController
      end

      if user.facility_director_of?(resource) && SettingsHelper.feature_off?(:facility_directors_can_manage_price_groups)
        cannot [:create, :edit, :update, :destroy], PriceGroup
        cannot [:create, :edit, :update, :destroy], [PricePolicy, InstrumentPricePolicy, ItemPricePolicy, ServicePricePolicy]
      end

    elsif resource.is_a?(Account)
      if user.account_administrator_of?(resource)
        can :manage, Account
        can :manage, AccountUser
        can [:show, :suspend, :unsuspend, :user_search, :user_accounts, :statements, :show_statement, :index], Statement
      end

    elsif resource.is_a?(Reservation)
      # TODO: Add :accessory hash back in to hide hidden accessories from non-admin users
      # See task #55479
      can :read, ProductAccessory # , :accessory => { :is_hidden => false }

      if user.operator_of?(resource.product.facility)
        can :read, ProductAccessory
        can :manage, Reservation
      elsif resource.order.try(:user_id) == user.id
        can [:read, :create, :update, :destroy, :start_stop, :move], Reservation
      end

    elsif resource.is_a?(TrainingRequest)
      can :create, TrainingRequest

      if user.facility_director_of?(resource.product.facility) ||
         in_role?(user, resource.product.facility, UserRole::FACILITY_SENIOR_STAFF)
        can :manage, TrainingRequest
      end
    end

    ability_extender.extend(user, resource)
  end

  def in_role?(user, facility, *roles)
    # facility_user_roles returns full objects; we just want the names
    facility_roles = user.facility_user_roles(facility).map(&:role)
    # do the roles the user is part of match any of the potential roles
    (facility_roles & roles).any?
  end

  private

  def order_details_ability(user, resource)
    # Purchaser
    can [:add_accessories, :sample_results, :sample_results_zip, :show, :update, :cancel, :template_results,
         :order_file, :upload_order_file, :remove_order_file], OrderDetail, order: { user_id: user.id }
    # Facility managers
    can :manage, OrderDetail, order: { facility_id: resource.order.facility_id } if user.operator_of?(resource.facility)
    # Account owners/business admins
    can [:show, :update, :dispute], OrderDetail, account: { id: resource.account_id } if user.account_administrator_of?(resource.account)
  end

  def user_has_facility_role?(user)
    (user.user_roles.map(&:role) & UserRole.facility_roles).any?
  end

  def editable_global_group?(resource)
    resource.global? && resource.admin_editable?
  end

  def ability_extender
    @extender ||= AbilityExtensionManager.new(self)
  end

end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

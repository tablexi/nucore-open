# frozen_string_literal: true

class UserAccountsController < ApplicationController
  admin_tab :all
  layout "two_column"

  before_action :init_current_facility
  load_resource class: "User", id_param: :user_id, instance_name: :user
  authorize_resource class: AccountUser
  before_action { @active_tab = "admin_users" }
  before_action :load_accounts

  def edit
  end

  def update
    @user.assign_attributes(user_params)

    account_users_to_destroy = @user.account_users.select(&:marked_for_destruction?)
    clear_owners(account_users_to_destroy)
    account_users_to_destroy.each { |account_user| account_user.deleted_by = current_user.id }

    if @user.save
      account_users_to_destroy.each do |account_user|
        LogEvent.log(account_user, :delete, current_user)
      end
      redirect_to facility_user_accounts_path(current_facility, @user), flash: { notice: t(".updated", user_name: @user.full_name) }
    else
      flash.now[:error] = t(".could_not_update", user_name: @user.full_name)
      render :edit
    end
  end

  private

  def user_params
    permitted = params.require(:user).permit(account_users_attributes: [:id, :_destroy])
    submitted = permitted[:account_users_attributes]
    return permitted if submitted.blank?

    editable_ids = account_users_for_facility.ids.map(&:to_s)
    permitted[:account_users_attributes] = submitted.select do |_index, attributes|
      editable_ids.include?(attributes[:id].to_s)
    end
    permitted
  end

  def load_accounts
    @accounts = @user.accounts.includes(:owner_user).for_facility(current_facility)
  end

  def account_users_for_facility
    @account_users_for_facility ||=
      @user.account_users.joins(:account).merge(Account.for_facility(current_facility))
  end
  helper_method :account_users_for_facility

  def clear_owners(accounts)
    # Unmark owner records for destruction
    accounts.select(&:owner?).each { |au| au.reload }
    accounts.reject!(&:owner?)
  end

end

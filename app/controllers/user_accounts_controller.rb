# frozen_string_literal: true

class UserAccountsController < ApplicationController
  admin_tab :all
  before_action :init_current_facility
  layout "two_column"
  load_and_authorize_resource class: "User", id_param: :user_id, instance_name: :user

  def show
    @active_tab = "admin_users"
    @accounts = @user.accounts.for_facility(current_facility)
  end
end

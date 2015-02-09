class UserPriceGroupMembersController < ApplicationController
  include PriceGroupMembersController

  before_filter :require_manage_members_ability!

  private

  def after_create_redirect
    redirect_to users_facility_price_group_path(current_facility, @price_group)
  end

  def after_destroy_redirect
    redirect_to users_facility_price_group_path(current_facility, @price_group)
  end

  def create_flash_arguments
    {
      full_name: price_group_member.user.full_name,
      price_group_name: @price_group.name
    }
  end

  def price_group_member
    @user_price_group_member.user ||= User.find(params[:user_id])
    @user_price_group_member.price_group ||= @price_group
    @user_price_group_member
  end

  def require_manage_members_ability!
    return if @price_group_ability.can?(:manage_members, @price_group)
    raise ActiveRecord::RecordNotFound
  end
end

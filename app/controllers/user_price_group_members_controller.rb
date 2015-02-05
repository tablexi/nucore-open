class UserPriceGroupMembersController < ApplicationController
  include PriceGroupMembersController

  before_filter :require_manage_members_ability!

  # GET /price_group_members/new
  def new; end

  # GET /facilities/:facility_id/price_groups/:price_group_id/user_price_group_members/create
  def create
    if price_group_member.save
      flash[:notice] = I18n.t("controllers.user_price_group_members.create.notice", create_flash_arguments)
    else
      flash[:error] = I18n.t("controllers.user_price_group_members.create.error", create_flash_arguments)
    end
    redirect_to users_facility_price_group_path(current_facility, @price_group)
  end

  # DELETE /price_group_members/:id
  def destroy
    if destroy_price_group_member!
      flash[:notice] = I18n.t("controllers.user_price_group_members.destroy.notice")
    else
      flash[:error] = I18n.t("controllers.user_price_group_members.destroy.error")
    end

    redirect_to users_facility_price_group_path(current_facility, @price_group)
  end

  private

  def create_flash_arguments
    {
      full_name: price_group_member.user.full_name,
      price_group_name: @price_group.name,
    }
  end

  def destroy_user_price_group_member!
    UserPriceGroupMember
    .find(:first, conditions: { price_group_id: @price_group.id, id: params[:id] })
    .destroy
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

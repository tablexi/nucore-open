class UserPriceGroupMembersController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  
  layout 'two_column'

  load_and_authorize_resource

  def initialize
    @active_tab = 'admin_facility'
    super
  end

  # GET /price_group_members/new
  def new
    @price_group = current_facility.price_groups.find(params[:price_group_id])
  end

  # GET /facilities/:facility_id/price_groups/:price_group_id/user_price_group_members/create
  def create
    @price_group = current_facility.price_groups.find(params[:price_group_id])
    raise ActiveRecord::RecordNotFound if @price_group.facility_id.nil?
    
    @user = User.find(params[:user_id])
    @user_price_group_member = UserPriceGroupMember.new(:price_group => @price_group, :user => @user)

    if @user_price_group_member.save
      flash[:notice] = "#{@user_price_group_member.user.full_name} was added to the #{@price_group.name} Price Group"
    else
      flash[:error] = "An error was encountered while trying to add #{@user_price_group_member.user.full_name} to the #{@price_group.name} Price Group"
    end
    redirect_to(users_facility_price_group_url(current_facility, @price_group))
  end

  # DELETE /price_group_members/1
  def destroy
    @price_group = current_facility.price_groups.find(params[:price_group_id])
    @user_price_group_member = UserPriceGroupMember.find(:first, :conditions => { :price_group_id => @price_group.id, :id =>params[:id]} )

   if @user_price_group_member.destroy
     flash[:notice] = "The user was successfully removed from the Price Group"
   else
     flash[:error] = "An error was encountered while attempting to remove the user from the Price Group"
   end
   redirect_to(users_facility_price_group_url(current_facility, @price_group))
  end

end

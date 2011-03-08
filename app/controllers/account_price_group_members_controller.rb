class AccountPriceGroupMembersController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource
  
  layout 'two_column'
  
  def initialize
    @active_tab = 'admin_facility'
    super
  end

  # GET /price_group_members/new
  def new
    @price_group = current_facility.price_groups.find(params[:price_group_id])
    @account_price_group_member = AccountPriceGroupMember.new
  end

  # GET /facilities/:facility_id/price_groups/:price_group_id/account_price_group_members/create
  def create
    @price_group = current_facility.price_groups.find(params[:price_group_id])
    @account     = Account.find(params[:account_id])
    @account_price_group_member = AccountPriceGroupMember.new(:price_group => @price_group, :account => @account)

   if @account_price_group_member.save
     flash[:notice] = "#{@account_price_group_member.account.account_number} was added to the #{@price_group.name} Price Group."
   else
     flash[:error] = "An error was encountered while trying to add account #{@account_price_group_member.account.account_number} to the #{@price_group.name} Price Group."
   end
   redirect_to([current_facility, @price_group])
  end

  # DELETE /price_group_members/1
  def destroy
    @price_group = current_facility.price_groups.find(params[:price_group_id])
    @account_price_group_member = AccountPriceGroupMember.find(:first, :conditions => { :price_group_id => @price_group.id, :id =>params[:id]} )

    if @account_price_group_member.destroy
     flash[:notice] = "The account was successfully removed from the Price Group"
    else
      flash[:error] = "An error was encountered while attempting to remove the account from the Price Group"
    end
    redirect_to(facility_price_group_url(current_facility, @price_group))
  end

  def search_results
    @limit = 25
    @price_group = current_facility.price_groups.find(params[:price_group_id])

    term = generate_multipart_like_search_term(params[:search_term])
    if params[:search_term].length > 0
      conditions = ["LOWER(account_number) LIKE ?", term]
      @accounts = Account.find(:all, :conditions => conditions, :order => "account_number", :limit => @limit)
      @count = Account.count(:all, :conditions => conditions)
    end
    respond_to do |format|
      format.html { render :layout => false }
    end
  end
end

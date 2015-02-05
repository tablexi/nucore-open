class AccountPriceGroupMembersController < ApplicationController
  include PriceGroupMembersController

  # GET /price_group_members/new
  def new
    @account_price_group_member = AccountPriceGroupMember.new
  end

  # GET /facilities/:facility_id/price_groups/:price_group_id/account_price_group_members/create
  def create # TODO very similar to UserPriceGroupMembersController#create
    if price_group_member.save
      flash[:notice] = I18n.t("controllers.account_price_group_members.create.notice", create_flash_arguments)
    else
      flash[:error] = I18n.t("controllers.account_price_group_members.create.error", create_flash_arguments)
    end
    redirect_to [current_facility, @price_group]
  end

  # DELETE /price_group_members/:id
  def destroy # TODO very similar to UserPriceGroupMembersController#destroy
    if destroy_price_group_member!
      flash[:notice] = I18n.t("controllers.account_price_group_members.destroy.notice")
    else
      flash[:error] = I18n.t("controllers.account_price_group_members.destroy.error")
    end
    redirect_to facility_price_group_path(current_facility, @price_group)
  end

  # POST /facilities/:facility_id/price_groups/:price_group_id/account_price_group_members/search_results
  def search_results
    @limit = 25
    set_search_conditions if params[:search_term].present?
    render layout: false
  end

  private

  def account
    @account ||= Account.find(params[:account_id])
  end

  def price_group_member # TODO very similar to UserPriceGroupMembersController#price_group_member
    @account_price_group_member.account ||= account
    @account_price_group_member.price_group ||= @price_group
    @account_price_group_member
  end

  def create_flash_arguments # TODO very similar to UserPriceGroupMembersController#create_flash_arguments
    {
      account_number: price_group_member.account.account_number,
      price_group_name: @price_group.name,
    }
  end

  def search_conditions
    @search_conditions ||= [
      "LOWER(account_number) LIKE ?",
      generate_multipart_like_search_term(params[:search_term]),
    ]
  end

  def set_search_conditions
    @accounts = Account.find(:all,
      conditions: search_conditions,
      order: "account_number",
      limit: @limit
    )
    @count = Account.count(:all, conditions: search_conditions)
  end
end

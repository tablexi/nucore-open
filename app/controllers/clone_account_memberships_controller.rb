class CloneAccountMembershipsController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_user
  before_action { @active_tab = "accounts" }

  layout -> { request.xhr? ? false : "two_column" }

  def index
  end

  def search
    @users, _count = UserFinder.search(params[:search_term])
    render :search
  end

  def new
  end

  def create
  end

  private

  def init_user
    @user = User.find(params[:user_id])
  end

end

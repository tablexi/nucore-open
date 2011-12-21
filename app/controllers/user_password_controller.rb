class UserPasswordController < ApplicationController
  before_filter :authenticate_user!, :only => :edit_current
  before_filter :no_user_allowed, :only => [:reset, :edit, :update]
  layout "application"
  # GET /users/password/edit_current
  # POST /users/password/edit_current
  def edit_current
    @user = current_user

    unless @user.password_updatable?
      render :no_password, :layout => "application" and return
    end
    
    if request.post? and @user.update_password_confirm_current(params[:user])
      @user.clean_up_passwords
      flash[:notice] = I18n.t("user_password.edit.success")
    end    
  end

  
  def reset
    if request.post? and params[:user]
      @user = User.find_by_email(params[:user][:email])
      if @user
        if @user.password_updatable?
          @user.send_reset_password_instructions
          flash[:notice] = I18n.t("user_password.reset.success", :email => @user.email)
          redirect_to new_user_session_path
        else
          flash.now[:error] = I18n.t("activerecord.errors.models.user.password_not_updatable")
        end
      else
        flash.now[:error] = I18n.t("user_password.reset.not_found", :email => params[:user][:email])
      end
    end
  end
  
  def edit
    unless params[:reset_password_token] and @user = User.find_by_reset_password_token(params[:reset_password_token]) and @user.password_updatable? and @user.reset_password_period_valid?
      flash[:error] = I18n.t("activerecord.errors.models.user.invalid_token")
      redirect_to :action => :reset  
    end
  end
  
  def update
    unless params[:user] and params[:user][:reset_password_token] and @user = User.find_by_reset_password_token(params[:user][:reset_password_token]) and @user.password_updatable? and @user.reset_password_period_valid?
      flash[:error] = I18n.t("activerecord.errors.models.user.invalid_token")
      redirect_to :action => :reset and return  
    end
    # devise's reset has problems with the ldap module enabled and no ldap.yml
    # @user = User.reset_password_by_token(params[:user])
    @user.update_password(params[:user])
    if @user.errors.empty?
      flash[:notice] = I18n.t("user_password.edit.success")
      sign_in(@user)
      redirect_to :root and return
    end
    render :action => :edit
  end
  
  private
  def no_user_allowed
    if current_user
      redirect_to :action => :edit_current
      return false
    end
  end
end

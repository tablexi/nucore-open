class UserPasswordController < ApplicationController
  before_filter :authenticate_user!, :only => :edit_current
  before_filter :no_user_allowed, :only => [:reset, :edit, :update]
  layout "application"
  # GET /users/password/edit_current
  # POST /users/password/edit_current
  def edit_current
    @user = current_user

    unless @user.external?
      render :no_password, :layout => "application" and return
    end
    
    if request.post? and @user.update_password_confirm_current(params[:user])
      flash[:notice] = "Your password has been updated" 
    end    
  end

  
  def reset
    if request.post? and params[:user]
      @user = User.find_by_email(params[:user][:email])
      if @user
        if @user.external?
          @user.send_reset_password_instructions
          flash[:notice] = "Instructions on how to reset your password have been sent to #{@user.email}"
          redirect_to new_user_session_path
        else
          flash.now[:error] = "We cannot reset the password for that account. Please change it via the NetID website."
        end
      else
        flash.now[:error] = "We cannot find #{params[:user][:email]} in our records."
      end
    end
  end
  
  def edit
    unless params[:reset_password_token] and @user = User.find_by_reset_password_token(params[:reset_password_token]) and @user.external?
      flash[:error] = "The token is either invalid or has expired."
      redirect_to :action => :reset  
    end
  end
  
  def update
    unless params[:user] and params[:user][:reset_password_token] and @user = User.find_by_reset_password_token(params[:user][:reset_password_token]) and @user.external?
      flash[:error] = "The token is either invalid or has expired."
      redirect_to :action => :reset and return  
    end
    #@user = User.reset_password_by_token(params[:user])
    @user.update_password(params[:user])
    if @user.errors.empty?
      flash[:notice] = "Your password has successfully been reset"
      sign_in(@user)
      redirect_to new_user_session_path and return
    end
    puts @user
    render :action => :edit
  end
  
  private
  def no_user_allowed
    if current_user
      @hide_form = true
      flash.now[:error] = "You should not be accessing this page while already logged in."
      return false
    end
  end
end

# if params[:reset_password_token]
        # @user = User.find_by_reset_password_token(params[:reset_password_token])
        # if @user and @user.external?
          # render :action => :password, :layout => "application" and return
        # end
        # flash.now[:error] = "That link you clicked is no longer valid."
      # end
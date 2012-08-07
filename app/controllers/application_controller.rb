# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include DateHelper

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Make the following methods available to all views
  helper_method :current_facility, :session_user, :manageable_facilities, :operable_facilities, :acting_user, :acting_as?, :check_acting_as, :current_cart, :all_facility?, :backend? 

  # Navigation tabs configuration
  attr_accessor :active_tab
  include NavTab
  
  # return whatever facility is indicated by the :facility_id or :id url parameter
  # UNLESS that url parameter has the value of 'all'
  # in which case, return the all facility
  def current_facility
    return unless facility_id = params[:facility_id] || params[:id]

    if facility_id.present? and facility_id == 'all'
      @current_facility ||= all_facility
    else
      @current_facility ||= Facility.find_by_url_name(facility_id.to_s)
    end
  end

  ## sentinal value meaning all facilities
  def all_facility
    @@all_facility ||= Facility.new(:url_name => 'all', :name => "Cross-Facility", :abbreviation => 'ALL')
  end

  def all_facility?
    current_facility == all_facility
  end

  def init_current_facility
    raise ActiveRecord::RecordNotFound unless current_facility
  end

  #TODO: refactor existing calls of this definition to use this helper 
  def current_cart
    acting_user.cart(session_user)
  end
  
  def init_current_account
    @account = Account.find(params[:account_id] || params[:id])
  end

  def check_acting_as
    raise NUCore::NotPermittedWhileActingAs if acting_as?
  end

  def backend?
    params[:controller].starts_with?("facilit")
  end

  # authorization before_filter for billing actions
  def check_billing_access
    # something has gone wrong,
    # this before_filter shouldn't be run
    raise ActiveRecord::RecordNotFound unless current_facility

    authorize! :manage_billing, current_facility

  end


  # helper for actions in the 'Billing' manager tab
  # 
  # Purpose:
  #   used to get facilities normally used to scope down
  #   which order_details / journals are shown within the tables
  #
  # Returns
  #   returns an ActiveRecord::Relation of facilities
  #   which order_details / journals should be limited to
  #   when running a transaction search or working in the billing tab
  #
  # depends heavily on value of current_facility
  #
  # interprets the sentinel all_facility as all facilities
  def manageable_facilities
    @manageable_facilities = case current_facility

    when all_facility
      # if client ever wants cross-facility billing for a subset of facilities,
      # make this return session_user.manageable_facilities in the case of all_facility
      Facility.scoped
    when nil 
      session_user.manageable_facilities
    else # only facility that can be managed is the current facility
      Facility.where(:id => current_facility.id)
    end
  end

  # return an ActiveRecord:Relation of facilities where this user has a role (ie is staff or higher)
  # Administrator and Billing Administrator get a relation of all facilities
  def operable_facilities
    @operable_facilities ||= (session_user.blank? ? [] : session_user.operable_facilities)
  end

  # BCSEC legacy method. Kept to give us ability to override devises #current_user.
  def session_user
    begin
      @session_user ||= current_user
    rescue
      nil
    end
  end

  def acting_user
    @acting_user ||= User.find_by_id(session[:acting_user_id]) || session_user
  end

  def acting_as?
    return false if session_user.nil?
    acting_user.object_id != session_user.object_id
  end

  # Global exception handlers
  rescue_from ActiveRecord::RecordNotFound do |exception|
    Rails.logger.debug("#{exception.message}: #{exception.backtrace.join("\n")}") unless Rails.env.production?
    render_404
  end
  
  rescue_from ActionController::RoutingError do |exception|
    Rails.logger.debug("#{exception.message}: #{exception.backtrace.join("\n")}") unless Rails.env.production?
    render_404
  end

  def render_404
    render :file => '/404', :status => 404, :layout => 'application'
  end

  rescue_from NUCore::PermissionDenied, CanCan::AccessDenied, :with => :render_403
  def render_403(exception)
    # if current_user is nil, the user should be redirected to login
    if current_user
      render :file => '/403', :status => 403, :layout => 'application'
    else
      redirect_to new_user_session_path
    end
  end

  rescue_from NUCore::NotPermittedWhileActingAs, :with => :render_acting_error
  def render_acting_error
    render :file => '/acting_error', :status => 403, :layout => 'application'
  end

  # TODO: move to shared lib as this doesn't depend on state
  def generate_multipart_like_search_term(raw_term)
    term = (raw_term || '').strip
    term.tr_s! ' ', '%'
    term = '%' + term + '%'
    term.downcase
  end

  #
  # Customize Devise redirect after login
  def after_sign_in_path_for(resource)
    session[:requested_params] || super
  end


  private
  
  def current_ability
    @current_ability ||= Ability.new(current_user, ability_resource, self)
  end

  #
  # The +Ability+ class, which is used by cancan for authorization,
  # determines authorization by user and some resource. That resource
  # is returned by this method. By default it is #current_facility.
  # Override here to easily change the resource.
  def ability_resource
    return current_facility
  end

  def remove_ugly_params_and_redirect
    if (params[:commit] && request.get?)
      remove_ugly_params
      # redirect to self
      redirect_to params
      return false
    end
  end
  def remove_ugly_params
    [:commit, :utf8, :authenticity_token].each do |p|
      params.delete(p)
    end
  end
end

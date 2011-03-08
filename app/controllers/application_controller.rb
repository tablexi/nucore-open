# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Make the following methods available to all views
  helper_method :current_facility, :session_user, :manageable_facilities, :acting_user, :acting_as?, :check_acting_as

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  attr_accessor :active_tab

  # Navigation tabs configuration
  include NavTab

  # accessor method for the current facility
  def current_facility
    @current_facility
  end

  # initialize the current facility from the params hash
  def init_current_facility
    @current_facility = Facility.find_by_url_name!(params[:facility_id] || params[:id])
  end

  def check_acting_as
    raise NUCore::NotPermittedWhileActingAs if acting_as?
  end

  # return the list of manageable facilities
  def manageable_facilities
    return @manageable_facilities ||= (session_user.blank? ? [] : session_user.facilities)
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
    @acting_user ||= session[:acting_user_id] ? User.find(session[:acting_user_id]) : session_user
  end

  def acting_as?
    return false if session_user.nil?
    acting_user.object_id != session_user.object_id
  end

  # Global exception handlers
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  def render_404
    render :file => '/404', :status => 404, :layout => 'application'
  end

  rescue_from NUCore::PermissionDenied, CanCan::AccessDenied, :with => :render_403
  def render_403
    # if current_user is nil, the user should be redirected to login
    render :file => '/403', :status => 403, :layout => 'application' unless current_user.nil?
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

end

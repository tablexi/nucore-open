class PricePoliciesController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_product
  before_filter :init_price_policy, :except => [ :index, :new ]

  load_and_authorize_resource

  layout 'two_column'


  def initialize
    @active_tab = 'admin_products'
    super
  end


  private

  def init_product
    model_name=self.class.name.gsub('Controller', '').singularize
    product_var=model_name.gsub('PricePolicy', '').downcase
    var=current_facility.method(product_var.pluralize).call.find_by_url_name!(params["#{product_var}_id".to_sym])
    instance_variable_set("@#{product_var}", var)
  end


  #
  # Override CanCan's find -- it won't properly search by zoned date
  def init_price_policy
    model_name=self.class.name.gsub('Controller', '').singularize
    product_var="@#{model_name.gsub('PricePolicy', '').downcase}"
    instance_variable_set(
      "@#{model_name.underscore}",
      model_name.constantize.for_date(instance_variable_get(product_var), start_date_from_params).first
    )
  end


  def start_date_from_params
    start_date=params[:id] || params[:start_date]
    return unless start_date
    format=start_date.include?('/') ? "%m/%d/%Y" : "%Y-%m-%d"
    Date.strptime(start_date, format)
  end

end
class ProductForCart

  include TextHelpers::Translation

  attr_accessor :error_message
  attr_accessor :error_path

  def initialize(product)
    @product = product
  end

  def purchasable_by?(acting_user, session_user)
    raise NUCore::PermissionDenied unless product.is_accessible_to_user?(session_user)
    return false if acting_user.blank?

    if !product.available_for_purchase?
      @error_message = text(".not_available", i18n_params)
    elsif associated_price_policies(product).none?
      @error_message = text(".pricing_not_available", i18n_params)
    elsif !product.can_be_used_by?(acting_user) && !user_can_override_restrictions_on_product?(session_user, product)
      if SettingsHelper.feature_on?(:training_requests)
        if TrainingRequest.submitted?(session_user, product)
          @error_message = text("models.product_for_cart.already_requested_access", i18n_params)
          @error_path = url_helpers.facility_path(product.facility)
        else
          @error_path = url_helpers.new_facility_product_training_request_path(product.facility, product)
        end
      else
        @error_message = html(".requires_approval", i18n_params)
      end
    elsif !product.can_purchase?(price_group_ids_for_user(acting_user))
      @error_message = text(".no_price_groups", i18n_params)
    elsif acting_user.accounts_for_product(product).blank?
      @error_message = text(".no_accounts", i18n_params)
    elsif acting_as?(acting_user, session_user) && !session_user.operator_of?(product.facility)
      @error_message = text(".not_authorized_to_order_on_behalf", i18n_params)
    end

    [error_message, error_path].all?(&:nil?)
  end

  protected

  def translation_scope
    "models.#{self.class.name.underscore}"
  end

  private

  attr_accessor :product

  def user_can_override_restrictions_on_product?(user, product)
    user.present? && user.can_override_restrictions?(product)
  end

  def price_group_ids_for_user(user)
    (user.price_groups + user.account_price_groups).flatten.uniq.map(&:id)
  end

  def associated_price_policies(product)
    product.is_a?(Bundle) ? product.products.flat_map(&:price_policies) : product.price_policies
  end

  def i18n_params
    product_type = product.class.model_name.human.downcase
    {
      email: product.email,
      facility: product.facility,
      product_name: product.name,
      product_type: product_type,
      product_type_plural: product_type.pluralize,
    }
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def acting_as?(acting_user, session_user)
    return false if session_user.nil?
    acting_user.object_id != session_user.object_id
  end

end

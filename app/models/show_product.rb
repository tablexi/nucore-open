class ShowProduct
  attr_reader :acting_user, :controller, :error, :login_required, :redirect, :session_user

  def initialize(controller, product, acting_user, session_user, acting_as)
    @controller = controller
    @product = product
    @acting_user = acting_user
    @session_user = session_user
    @acting_as = acting_as
  end

  def available_for_purchase?
    if @product.available_for_purchase?
      true
    else
      @error = error_message(:not_available, product: @product.to_s)
      false
    end
  end

  def user_logged_in?
    if acting_user.present?
      true
    else
      @login_required = true
      false
    end
  end

  def authorized_if_ordering_on_behalf?
    if @acting_as && !session_user.operator_of?(@product.facility)
      @error = error_message(:not_authorized_to_order_on_behalf)
      false
    else
      true
    end
  end

  def user_has_valid_payment_source?
    if acting_user.accounts_for_product(@product).any?
      true
    else
      @error = error_message(:no_accounts)
      false
    end
  end

  def acting_user_can_purchase?
    if @product.can_purchase?(acting_user_price_group_ids)
      true
    else
      @error = error_message(:not_in_price_group, name: @product.to_s)
      false
    end
  end

  def user_is_approved_to_use_product?
    if @product.can_be_used_by?(acting_user) || session_user_can_override_restrictions?(@product)
      true
    else
      if SettingsHelper.feature_on?(:training_requests)
        if TrainingRequest.submitted?(session_user, @product)
          @error = error_message(:already_requested_access)
          @redirect = controller.facility_path(current_facility)
        else
          @redirect = controller.new_facility_product_training_request_path(current_facility, @product)
        end
      else
        @error = requires_approval_error
      end
      false
    end
  end

  def able_to_add_to_cart?
    assert_product_is_accessible!
    @login_required = false

    available_for_purchase? &&
    user_logged_in? &&
    authorized_if_ordering_on_behalf? &&
    user_has_valid_payment_source? &&
    acting_user_can_purchase? &&
    user_is_approved_to_use_product?
  end

  def current_facility
    @product.facility
  end

  def error_message(key, *options)
    controller.t_model_error(@product.class, key, *options)
  end

  private

  def acting_user_price_group_ids
    (acting_user.price_groups + acting_user.account_price_groups)
    .flatten
    .uniq
    .map(&:id)
  end

  def assert_product_is_accessible!
    raise NUCore::PermissionDenied unless product_is_accessible?
  end

  def product_is_accessible?
    is_operator = session_user && session_user.operator_of?(current_facility)
    !(@product.is_archived? || (@product.is_hidden? && !is_operator))
  end

  def requires_approval_error
    error_message(
      :requires_approval_html,
      email: @product.email,
      facility: @product.facility,
      name: @product.to_s,
    ).html_safe
  end

  def session_user_can_override_restrictions?(product)
    session_user.present? && session_user.can_override_restrictions?(product)
  end
end

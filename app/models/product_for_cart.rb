class ProductForCart
  attr_accessor :error_message
  attr_accessor :error_path

  def initialize(product, controller)
    @product = product
    @controller = controller
  end

  def purchasable_by?(acting_user, session_user)
    return false if acting_user.blank?

    case
    when !product.available_for_purchase?
      @error_message = controller.text(".not_available", product: product)
    when !@product.can_be_used_by?(acting_user) && !user_can_override_restrictions_on_product?(session_user, product)
      if SettingsHelper.feature_on?(:training_requests)
        if TrainingRequest.submitted?(session_user, product)
          @error_message = controller.text("controllers.products_common.already_requested_access", product: product)
          @error_path = controller.facility_path(controller.current_facility)
        else
          @error_path = controller.new_facility_product_training_request_path(controller.current_facility, product)
        end
      else
        @error_message = controller.html(".requires_approval", email: product.email, facility: product.facility, product: product.class.model_name.human.downcase)
      end
    when !product.can_purchase?(price_group_ids_for_user(acting_user))
      @error_message = controller.text(".no_price_groups", product: product)
    when acting_user.accounts_for_product(product).blank?
      @error_message = controller.text(".no_accounts", product: product)
    when controller.acting_as? && !session_user.operator_of?(product.facility)
      @error_message = controller.text(".not_authorized_to_order_on_behalf", products: product.class.model_name.human(count: 2).downcase)
    end

    [@error_message, @error_path].all?(&:nil?)
  end

  private

  attr_accessor :controller
  attr_accessor :product

  def user_can_override_restrictions_on_product?(user, product)
    user.present? && user.can_override_restrictions?(product)
  end

  def price_group_ids_for_user(user)
    (user.price_groups + user.account_price_groups).flatten.uniq.map(&:id)
  end
end

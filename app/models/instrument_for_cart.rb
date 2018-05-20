class InstrumentForCart
  attr_accessor :error_message
  attr_accessor :error_path

  def initialize(instrument, controller)
    @instrument = instrument
    @controller = controller
  end

  def purchasable_by?(acting_user, session_user)
    case
    when !instrument.available_for_purchase?
      @error_message = controller.text(".not_available", product: instrument)
      @error_path = controller.facility_path(controller.current_facility)
      false
    when !@instrument.can_be_used_by?(acting_user) && !user_can_override_restrictions_on_instrument?(session_user, instrument)
      if SettingsHelper.feature_on?(:training_requests)
        if TrainingRequest.submitted?(session_user, instrument)
          @error_message = controller.text("controllers.products_common.already_requested_access", product: instrument)
          @error_path = controller.facility_path(controller.current_facility)
        else
          @error_path = controller.new_facility_product_training_request_path(controller.current_facility, instrument)
        end
      else
        @error_message = controller.html(".requires_approval", email: instrument.email, facility: instrument.facility, product: instrument.class.model_name.human.downcase)
      end
      false
    when !instrument.can_purchase?(price_group_ids_for_user(acting_user))
      @error_message = controller.text(".no_price_groups", product: instrument)
      false
    when acting_user.accounts_for_product(instrument).blank?
      @error_message = controller.text(".no_accounts")
      false
    when controller.acting_as? && !session_user.operator_of?(instrument.facility)
      @error_message = controller.text(".not_authorized_to_order_on_behalf", products: instrument.class.model_name.human(count: 2).downcase)
      false
    else
      true
    end
  end

  private

  attr_accessor :controller
  attr_accessor :instrument

  def user_can_override_restrictions_on_instrument?(user, instrument)
    user.present? && user.can_override_restrictions?(instrument)
  end

  def price_group_ids_for_user(user)
    (user.price_groups + user.account_price_groups).flatten.uniq.map(&:id)
  end
end

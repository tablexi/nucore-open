class InstrumentForCart < ProductForCart

  def purchasable_by?(acting_user, session_user)
    # If an instrument is not purchasable, we always redirect. Hence, if super
    # doesn’t set an error path due to some specific error, we set the error path
    # to the facility path.
    super.tap do |is_purchasable|
      @error_path ||= url_helpers.facility_path(product.facility) unless is_purchasable
    end
  end

  private

  def checks(acting_user, session_user)
    [user_is_present?(acting_user), product_has_schedule_rules?] + super
  end

  def user_is_present?(user)
    -> { @error_path = url_helpers.new_user_session_path if user.blank? }
  end

  def product_has_schedule_rules?
    -> { @error_message = text(".schedule_not_available", i18n_params) if product.schedule_rules.none? }
  end

end

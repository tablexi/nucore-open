class InstrumentForCart < ProductForCart
  def purchasable_by?(acting_user, session_user)
    super.tap do |success|
      if acting_user.blank?
        @error_path = controller.new_user_session_path
      elsif product.schedule_rules.none?
        @error_message = controller.text(".schedule_not_available", i18n_params)
      end

      # If an instrument is not purchasable, we always redirect. If ProductForCart
      # didn’t set an error path due to some specific error, we should redirect
      # back to the facility path.
      @error_path ||= url_helpers.facility_path(product.facility) unless success
    end
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end
end

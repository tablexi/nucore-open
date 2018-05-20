class InstrumentForCart < ProductForCart
  def purchasable_by?(acting_user, session_user)
    super.tap do
      if acting_user.blank?
        @error_path = controller.new_user_session_path
      else
        @error_path ||= controller.facility_path(controller.current_facility)
      end
    end
  end
end

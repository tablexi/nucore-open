class InstrumentForCart < ProductForCart
  def purchasable_by?(acting_user, session_user)
    if acting_user.blank?
      @error_path = controller.new_user_session_path
      false
    else
      super
    end
  end
end

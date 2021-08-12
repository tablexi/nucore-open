# frozen_string_literal: true

module HolidayValidations

  extend ActiveSupport::Concern

  included do
    validate :holiday_accessible, if: :starts_on_holiday?
  end

  def holiday_accessible
    if product.restrict_holiday_access? && user_restricted_on_holidays?
      errors.add(:base, :holiday_access_restricted)
    end
  end

  def user_restricted_on_holidays?
    return false if user.can_override_restrictions?(product)

    !product.access_group_for_user(user)&.allow_holiday_access
  end

  def starts_on_holiday?
    return false if event_start_date.blank?

    Holiday.on(event_start_date).present?
  end

  # Occupancies don't have a reserve_start_at date
  def event_start_date
    @event_start_date ||= respond_to?(:reserve_start_at) ? reserve_start_at : actual_start_at
  end

end

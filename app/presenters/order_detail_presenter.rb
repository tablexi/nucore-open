class OrderDetailPresenter < SimpleDelegator

  include ActionView::Helpers::NumberHelper
  include DateHelper
  include Rails.application.routes.url_helpers

  delegate :admin_editable?, to: :reservation, prefix: true
  delegate :template_result, to: :stored_files, prefix: true

  def self.wrap(order_details)
    order_details.map { |order_detail| new(order_detail) }
  end

  def actual_total
    format_as_currency(__getobj__.actual_total)
  end

  def description_as_html
    [bundle, product].compact.map do |description|
      ERB::Util.html_escape(description)
    end.join(" &mdash; ").html_safe
  end

  def edit_reservation_path
    edit_facility_order_order_detail_reservation_path(facility, order, id, reservation)
  end

  def estimated_total
    format_as_currency(__getobj__.estimated_total)
  end

  def ordered_at
    human_datetime(order.ordered_at)
  end

  def row_class
    reconcile_warning? ? "reconcile-warning" : ""
  end

  def show_order_path
    facility_order_path(facility, order)
  end

  def show_reservation_path
    facility_order_order_detail_reservation_path(facility, order, id, reservation)
  end

  def survey_url
    survey_completed? ? external_service_receiver.show_url : ""
  end

  private

  def format_as_currency(value)
    value.present? ? number_to_currency(value) : ""
  end

  # Is a fulfilled order detail nearing the end of the 90 day reconcile period?
  # Returns true if it is 60+ days fulfilled, false otherwise
  def reconcile_warning?
    !reconciled? && fulfilled_at.present? && fulfilled_at < 60.days.ago
  end

end

# frozen_string_literal: true

module ProductsHelper

  def price_policy_errors(product)
    if product.is_a?(Bundle)
      error_msg = t("price_policies.errors.missing_for_bundle") if product.products_missing_price_policies.any?
    elsif product.current_price_policies.none?
      error_msg = t("price_policies.errors.none_exist")
    end
    content_tag :span, error_msg, class: ["label", "label-important", "pull-right"] if error_msg
  end

  def options_for_control_mechanism
    Relay::CONTROL_MECHANISMS.inject(ActiveSupport::OrderedHash.new) do |hash, (key, _v)|
      human_value = t("instruments.instrument_fields.relay.control_mechanisms.#{key}")
      hash[human_value] = key
      hash
    end
  end

  def options_for_relay
    {
      RelaySynaccessRevA => RelaySynaccessRevA.name,
      RelaySynaccessRevB => RelaySynaccessRevB.name,
      RelayDataprobe => RelayDataprobe.name,
    }
  end

  def public_calendar_link(product, indent: false)
    if product.respond_to? :reservations
      opts = public_calendar_options(product)
      link_to "", facility_instrument_public_schedule_path(product.facility, product), opts
    elsif indent
      content_tag :span, "", class: "fa-lg fa-fw", style: "display: inline-block"
    end
  end

  def product_url_hint(product)
    public_send(
      "facility_#{product.class.name.underscore}_url",
      current_facility.url_name,
      "URL_NAME".html_safe,
    )
  end

  private

  def public_calendar_options(product)
    if current_facility&.show_instrument_availability? || !current_facility && product.facility.show_instrument_availability?
      public_calendar_availability_options(product)
    else
      { class: ["fa fa-calendar fa-lg fa-fw"],
        title: t("instruments.public_schedule.icon") }
    end
  end

  def public_calendar_availability_options(product)
    if product.offline?
      { class: ["fa fa-calendar fa-lg fa-fw", "in-use"],
        title: text("instruments.offline.note") }
    elsif product.walkup_available?
      { class: ["fa fa-calendar fa-lg fa-fw", "available"],
        title: text("instruments.public_schedule.available") }
    else
      { class: ["fa fa-calendar fa-lg fa-fw", "in-use"],
        title: text("instruments.public_schedule.unavailable") }
    end
  end

end

require "csv"

module Reports

  class ExportRaw

    include CsvExporter

    attr_reader :order_status_ids, :facility, :date_range_field

    def initialize(arguments)
      [:date_end, :date_start, :facility, :order_status_ids].each do |property|
        if arguments[property].present?
          instance_variable_set("@#{property}".to_sym, arguments[property])
        else
          raise ArgumentError, "Required argument '#{property}' is missing"
        end
      end
      @date_range_field = arguments[:date_range_field] || "journal_or_statement_date"
    end

    def description
      "#{facility.name} Export Raw, #{formatted_date_range}"
    end

    def translation_scope
      "controllers.general_reports"
    end

    private

    def default_report_hash
      {
        facility: :facility,
        order: :to_s,
        ordered_at: -> (od) { od.order.ordered_at },
        fulfilled_at: -> (od) { od.fulfilled_at },
        order_status: -> (od) { od.order_status.name },
        order_state: :state,
        ordered_by: -> (od) { od.created_by_user.username },
        first_name: -> (od) { od.created_by_user.first_name },
        last_name: -> (od) { od.created_by_user.last_name },
        email: -> (od) { od.created_by_user.email },
        purchaser: -> (od) { od.user.username },
        purchaser_first_name: -> (od) { od.user.first_name },
        purchaser_last_name: -> (od) { od.user.last_name },
        purchaser_email: -> (od) { od.user.email },
        product_id: -> (od) { od.product.url_name },
        product_type: -> (od) { od.product.type.underscore.humanize },
        product: -> (od) { od.product.name },
        quantity: :quantity,
        bundled_products: -> (od) { od.product.is_a?(Bundle) ? od.product.products.collect(&:name).join(" & ") : nil },
        account_type: -> (od) { od.account.type.underscore.humanize },
        affiliate: -> (od) { od.account.affiliate_to_s },
        account: -> (od) { od.account.account_number },
        account_description: -> (od) { od.account.description_to_s },
        account_expiration: -> (od) { od.account.expires_at },
        account_owner: -> (od) { od.account.owner_user.username },
        owner_first_name: -> (od) { od.account.owner_user.first_name },
        owner_last_name: -> (od) { od.account.owner_user.last_name },
        owner_email: -> (od) { od.account.owner_user.email },
        price_group: -> (od) { od.price_policy.try(:price_group).try(:name) },
        estimated_cost: -> (od) { as_currency(od.estimated_cost) },
        estimated_subsidy: -> (od) { as_currency(od.estimated_subsidy) },
        estimated_total: -> (od) { as_currency(od.estimated_total) },
        actual_cost: -> (od) { as_currency(od.actual_cost) },
        actual_subsidy: -> (od) { as_currency(od.actual_subsidy) },
        actual_total: -> (od) { as_currency(od.actual_total) },
        reservation_start_time: -> (od) { od.reservation.reserve_start_at if od.reservation },
        reservation_end_time: -> (od) { od.reservation.reserve_end_at if od.reservation },
        reservation_minutes: -> (od) { od.reservation.duration_mins if od.reservation },
        actual_start_time: -> (od) { od.reservation.actual_start_at if od.reservation },
        actual_end_time: -> (od) { od.reservation.actual_end_at if od.reservation },
        actual_minutes: -> (od) { od.reservation.actual_duration_mins if od.reservation },
        canceled_at: -> (od) { od.reservation.canceled_at if od.reservation },
        canceled_by: -> (od) { canceled_by_name(od.reservation) if od.reservation },
        note: :note,
        disputed_at: :dispute_at,
        dispute_reason: :dispute_reason,
        dispute_resolved_at: :dispute_resolved_at,
        dispute_resolved_reason: :dispute_resolved_reason,
        reviewed_at: :reviewed_at,
        statemented_on: -> (od) { od.statement.created_at if od.statement },
        journal_date: -> (od) { od.journal.journal_date if od.journal },
        reconciled_note: :reconciled_note,
        reconciled_at: :reconciled_at,
      }
    end

    def report_data_query
      Reports::Querier.new(
        order_status_id: @order_status_ids,
        current_facility: @facility,
        date_range_field: @date_range_field,
        date_range_start: date_start,
        date_range_end: date_end,
        includes: [:reservation, :statement],
        transformer_options: { reservations: true },
      ).perform
    end

    def as_currency(number)
      if number.present?
        ActionController::Base.helpers.number_to_currency(number)
      else
        ""
      end
    end

    def canceled_by_name(reservation)
      if reservation.canceled_by == 0
        I18n.t("reports.fields.auto_cancel_name")
      else
        reservation.canceled_by_user.try(:full_name)
      end
    end

  end

end

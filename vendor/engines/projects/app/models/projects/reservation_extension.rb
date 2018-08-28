# frozen_string_literal: true

module Projects

  module ReservationExtension

    extend ActiveSupport::Concern

    included do
      delegate :project_id, :project_id=, to: :order_detail, allow_nil: true
    end

  end

end

module SecureRooms

  module OrderDetailExtension

    extend ActiveSupport::Concern

    included do
      has_one :occupancy, dependent: :destroy, inverse_of: :order_detail, class_name: SecureRooms::Occupancy
    end

  end

end

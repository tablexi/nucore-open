module SangerSequencing
  class OrderDetail
    include ActiveModel::AttributeMethods

    def self.find(id)
      new(id: id)
    end

    attr_reader :id

    def initialize(attributes = {})
      @id = attributes[:id]
      @nucore_order_detail ||= ::OrderDetail.find(@id)
    end

    def cart_path
      Rails.application.routes.url_helpers.order_path(@nucore_order_detail.order_id)
    end

  end

end

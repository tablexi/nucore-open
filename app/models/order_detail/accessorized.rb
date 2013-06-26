module OrderDetail::Accessorized
  extend ActiveSupport::Concern

  included do
    belongs_to :product_accessory

    belongs_to :parent_order_detail, class_name: 'OrderDetail', :inverse_of => :child_order_details
    has_many   :child_order_details, class_name: 'OrderDetail', foreign_key: 'parent_order_detail_id', :inverse_of => :parent_order_detail

    after_save :update_children

    delegate :scaling_type, :to => :product_accessory
  end

  def accessories?
    product.product_accessories.any?
  end

  def update_children
    accessorizer = Accessories::Accessorizer.new(self)
    accessorizer.update_children
  end
end

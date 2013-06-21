module OrderDetail::Accessorized
  extend ActiveSupport::Concern

  included do
    belongs_to :parent_order_detail, class_name: 'OrderDetail'
    has_many   :child_order_details, class_name: 'OrderDetail', foreign_key: 'parent_order_detail_id'

    after_save :update_children
  end

  def update_children
    accessorizer = Accessories::Accessorizer.new(self)
    accessorizer.update_children
  end
end

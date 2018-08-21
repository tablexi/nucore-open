# frozen_string_literal: true

module OrderStatusesHelper

  def children_for_facility(class_or_item, facility_id, mover = nil)
    class_or_item = class_or_item.roots.where(facility_id: [nil, facility_id]) if class_or_item.is_a?(Class)
    items = Array(class_or_item)
    result = []
    items.each do |root|
      result += root.children.where(facility_id: [nil, facility_id]).map do |i|
        if mover.nil? || mover.new_record? || mover.move_possible?(i)
          [yield(i), i.id]
        end
      end.compact
    end
    result
  end

end

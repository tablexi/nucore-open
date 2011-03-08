module OrderStatusesHelper

  def children_for_facility(class_or_item, facility_id, mover = nil)
    class_or_item = class_or_item.roots.find(:all, :conditions => "facility_id = #{facility_id} OR facility_id IS NULL") if class_or_item.is_a?(Class)
    items = Array(class_or_item)
    result = []
    items.each do |root|
      result += root.children.find(:all, :conditions => "facility_id = #{facility_id} OR facility_id IS NULL").map do |i|
        if mover.nil? || mover.new_record? || mover.move_possible?(i)
          [yield(i), i.id]
        end
      end.compact
    end
    result
  end

  def root_options_for_facility(klass, facility_id)
    roots = klass.roots.find(:all, :conditions => "facility_id = #{facility_id} OR facility_id IS NULL")
    result = []
    roots.each do |root|
      result.push [root.name, root.id]
    end
    result
  end

end

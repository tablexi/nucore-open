class AddExtraOrderStatuses < ActiveRecord::Migration
  # Looks at settings.yml and finds any of the statuses declared to have a hook when an order
  # detail enters that status. Then check to make sure that status is in the database as a 
  # substatus of New.
  def self.up
    new_status = OrderStatus.find_by_name('New')
    OrderDetailObserver.status_change_hooks.keys.each do |status|
      OrderStatus.find_or_create_by_name_and_facility_id(:name => status.to_s.titleize, :facility_id => nil, :parent => new_status)
    end
  end

  def self.down
    new_status = OrderStatus.find_by_name('New')
    OrderDetailObserver.status_change_hooks.keys.each do |status|
      OrderStatus.destroy_all(:name => status.to_s.titleize, :facility_id => nil, :parent_id => new_status.id)
    end
  end
end

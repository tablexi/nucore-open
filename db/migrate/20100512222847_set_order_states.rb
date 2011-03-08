class SetOrderStates < ActiveRecord::Migration
  def self.up
    Order.all(:conditions => 'ordered_at IS NULL').each{|o| o.state = 'new'; o.save;}
    Order.all(:conditions => 'ordered_at IS NOT NULL').each{|o| o.state = 'purchased'; o.save;}
  end

  def self.down
    Order.all.each{|o| o.state = nil; o.save;}
  end
end

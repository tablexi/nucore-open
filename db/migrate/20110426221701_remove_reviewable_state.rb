class RemoveReviewableState < ActiveRecord::Migration

  def self.up
    reviewable, inprocess=OrderStatus.find_by_name('Reviewable'), OrderStatus.inprocess.first
    execute("UPDATE order_details SET order_status_id=#{inprocess.id},state='inprocess' WHERE order_status_id=#{reviewable.id} AND state='reviewable'")

    right, left=reviewable.right, reviewable.left
    diff=right-left

    # awesome_nested_set barfs trying to fix descendants on Oracle, so skip its shoddy work and rebuild tree manually
    reviewable.skip_before_destroy=true
    reviewable.destroy

    execute("UPDATE order_statuses SET lft=(lft-(#{diff}+1)), rgt=(rgt-(#{diff}+1)) WHERE lft > #{right}")
  end

  def self.down
    OrderStatus.create!(:name => 'Reviewable')
  end

end

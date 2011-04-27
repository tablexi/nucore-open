class RemoveReviewableState < ActiveRecord::Migration

  def self.up
    reviewable, inprocess=OrderStatus.find_by_name('Reviewable'), OrderStatus.inprocess.first
    execute("UPDATE order_details SET order_status_id=#{inprocess.id},state='inprocess' WHERE order_status_id=#{reviewable.id} AND state='reviewable'")

    begin
      # reorder the tree by moving reviewable to the very end
      reviewable.move_right
    end while reviewable.right

    # awesome_nested_set barfs trying to fix descendants on Oracle, so skip its shoddy work
    reviewable.skip_before_destroy=true
    reviewable.destroy
  end

  def self.down
    OrderStatus.create!(:name => 'Reviewable')
  end

end

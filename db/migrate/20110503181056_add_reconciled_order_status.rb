class AddReconciledOrderStatus < ActiveRecord::Migration
  def self.up
    OrderStatus.create!(:name => 'Reconciled')
  end

  def self.down
    os=OrderStatus.find_by_name('Reconciled')
    os.destroy if os
  end
end

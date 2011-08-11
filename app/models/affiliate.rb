class Affiliate < ActiveRecord::Base
  validates_uniqueness_of :name

  OTHER=where(:name => 'Other').first

  before_destroy :destroyable?

  def destroyable?
    self != OTHER
  end
end

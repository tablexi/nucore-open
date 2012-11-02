class Affiliate < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  def self.OTHER
    find_or_create_by_name('Other')
  end

  before_destroy :destroyable?

  def destroyable?
    self != self.class.OTHER
  end
end

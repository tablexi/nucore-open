class Affiliate < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  OTHER=find_or_create_by_name('Other') #where(:name => 'Other').first

  before_destroy :destroyable?

  def destroyable?
    self != OTHER
  end
end

class Affiliate < ActiveRecord::Base
  validates_uniqueness_of :name

  OTHER=where(:name => 'Other').first
end

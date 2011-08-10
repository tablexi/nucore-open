class Affiliate < ActiveRecord::Base
  validates_length_of :name, :minimum => 1

  OTHER=where(:name => 'Other').first
end

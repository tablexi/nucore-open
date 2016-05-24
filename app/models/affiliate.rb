class Affiliate < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name

  def self.OTHER
    @@other ||= find_or_create_by(name: "Other")
  end

  def self.ordered_by_name
    order(:name)
  end

  before_destroy :destroyable?

  def destroyable?
    self != self.class.OTHER
  end

end

class Affiliate < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :destroyable, -> { where.not(id: self.OTHER.id) }
  scope :by_name, -> { order(:name) }

  def self.OTHER
    @@other ||= find_or_create_by(name: "Other") { |a| a.subaffiliates_enabled = true }
  end

  before_destroy :destroyable?

  def destroyable?
    !other?
  end

  def other?
    self == self.class.OTHER
  end

end

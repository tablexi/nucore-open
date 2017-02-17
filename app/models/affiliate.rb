class Affiliate < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :destroyable, -> { where.not(id: self.OTHER.id) }
  scope :by_name, -> { order(:name) }

  def self.OTHER
    @@other ||= find_or_create_by(name: "Other", subaffiliates_enabled: true)
  end

  before_destroy :destroyable?

  def destroyable?
    self != self.class.OTHER
  end

  def other?
    self == self.class.OTHER
  end

end

# frozen_string_literal: true

class Affiliate < ApplicationRecord

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :destroyable, -> { where.not(id: self.OTHER.id) }
  scope :by_name, -> { order(:name) }

  def self.OTHER # rubocop:disable Naming/MethodName
    @@other ||= find_or_create_by(name: "Other") { |a| a.subaffiliates_enabled = true }
  end

  before_destroy { throw :abort if other? }

  def other?
    self == self.class.OTHER
  end

end

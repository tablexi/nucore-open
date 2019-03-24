# frozen_string_literal: true

class Schedule < ApplicationRecord

  belongs_to :facility

  has_many :admin_reservations, through: :products
  has_many :facility_instruments, -> { not_archived }, class_name: "Instrument"
  has_many :products, class_name: "Instrument"
  has_many :public_instruments, -> { active }, class_name: "Instrument"
  has_many :reservations, through: :products

  validates_presence_of :facility

  scope :active, -> { where(id: Product.not_archived.with_schedule.select(:schedule_id)).order(:name) }

  def shared?
    products.count > 1
  end

  def display_name
    key = "instruments.instrument_fields.schedule.#{shared? ? 'shared' : 'unshared'}"
    "#{I18n.t(key)}: #{name}"
  end

end

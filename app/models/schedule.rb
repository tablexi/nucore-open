# frozen_string_literal: true

class Schedule < ApplicationRecord

  # Associations
  # --------
  belongs_to :facility

  has_many :products, class_name: "Instrument"
  has_many :reservations, through: :products
  has_many :admin_reservations, through: :products

  # Validations
  # --------
  validates_presence_of :facility

  scope :active, -> { where(id: Product.not_archived.with_schedule.select(:schedule_id)).order(:name) }

  # Instance methods
  # --------

  def publicly_visible_products
    products.active
  end

  def facility_visible_products
    products.not_archived
  end

  def shared?
    products.count > 1
  end

  def display_name
    key = "instruments.instrument_fields.schedule.#{shared? ? 'shared' : 'unshared'}"
    "#{I18n.t(key)}: #{name}"
  end

end

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

  # Scopes
  # -------

  def self.active
    where("schedules.id in
      (select schedule_id
       from products
       where is_archived = :archived
       and schedule_id is not null
       group by schedule_id)",
          archived: false)
  end

  def self.ordered
    order(:name)
  end

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

# frozen_string_literal: true

class OrderStatus < ApplicationRecord

  has_many :order_details
  belongs_to :facility
  belongs_to :parent, class_name: "OrderStatus"

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:parent_id, :facility_id], case_sensitive: false
  validates_each :parent_id do |model, attr, value|
    begin
      model.errors.add(attr, "must be a root") unless value.nil? || OrderStatus.unscoped.find(value).root?
    rescue => e
      model.errors.add(attr, "must be a valid root")
    end
  end

  scope :for_facility, ->(facility) { where(facility_id: [nil, facility.id]).order(:lft) }

  STATUS_ORDER = ["New", "In Process", "Canceled", "Complete", "Reconciled"].freeze

  # This one is different because `new` is a reserved keyword
  def self.new_status
    find_by(name: "New")
  end

  def self.complete
    find_by(name: "Complete")
  end

  def self.canceled
    find_by(name: "Canceled")
  end

  def self.in_process
    find_by(name: "In Process")
  end

  def self.reconciled
    find_by(name: "Reconciled")
  end

  def self.add_to_order_statuses(facility)
    non_protected_statuses(facility) - [canceled]
  end

  def self.roots
    where(parent_id: nil)
  end

  def self_and_descendants
    self.class.where(self.class.arel_table[:id].eq(self.id).or(self.class.arel_table[:parent_id].eq(self.id)))
  end

  def root?
    parent_id.nil?
  end

  def root
    parent || self
  end

  def editable?
    !!facility
  end

  def state_name
    root.name.downcase.delete(" ").to_sym
  end

  def before?(o)
    index = STATUS_ORDER.index(root.name)
    other_index = STATUS_ORDER.index(o.root.name)

    (index < other_index) || (index == other_index && id < o.id)
  end

  def position
    [STATUS_ORDER.index(root.name), id]
  end

  def level
    root? ? 0 : 1
  end

  def name_with_level
    "#{'-' * level} #{name}".strip
  end

  def to_s
    name
  end

  def root_canceled?
    root == OrderStatus.canceled
  end

  class << self

    def root_statuses
      roots.sort_by(&:position)
    end

    def default_order_status
      root_statuses.first
    end

    def initial_statuses(facility)
      first_invalid_status = canceled
      statuses = facility.nil? ? all : facility.order_statuses
      statuses.select { |os| os.before?(first_invalid_status) }.sort_by(&:position)
    end

    def non_protected_statuses(facility)
      first_protected_status = reconciled
      statuses = facility.nil? ? all : facility.order_statuses
      statuses.select { |os| os.before?(first_protected_status) }.sort_by(&:position)
    end

  end

end

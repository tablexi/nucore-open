class Facility < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  module Overridable
    def can_pay_with_account?(account)
      true
    end
  end

  include Overridable

  before_validation :set_journal_mask, :on => :create

  has_many :order_statuses, :finder_sql => proc { "SELECT * FROM order_statuses WHERE facility_id = #{self.id} or facility_id IS NULL order by lft" }
  has_many :items
  has_many :services
  has_many :instruments
  has_many :bundles
  has_many :price_groups, :finder_sql => proc { "SELECT * FROM price_groups WHERE price_groups.facility_id = #{self.id} OR price_groups.facility_id IS NULL ORDER BY price_groups.is_internal DESC, price_groups.display_order ASC, price_groups.name ASC" }
  has_many :journals
  has_many :products
  has_many :schedules
  has_many :statements
  has_many :order_details, :through => :products do
    # extend to find all accounts that have ordered from the facility
    def accounts
      self.collect(&:account).compact.uniq
    end
  end
  has_many :order_imports, dependent: :destroy
  has_many :orders, :conditions => 'ordered_at IS NOT NULL'
  has_many :facility_accounts
  has_many :training_requests, through: :products
  has_many :user_roles, :dependent => :destroy
  has_many :users, :through => :user_roles

  validates_presence_of :name, :short_description, :abbreviation
  validate_url_name :url_name
  validates_uniqueness_of :abbreviation, :journal_mask, :case_sensitive => false
  validates_format_of    :abbreviation, :with => /^[a-zA-Z\d\-\.\s]+$/, :message => "may include letters, numbers, hyphens, spaces, or periods only"
  validates_format_of    :journal_mask, :with => /^C\d{2}$/, :message => "must be in the format C##"

  validates :short_description,
    length: { maximum: 300 },
    if: -> { SettingsHelper.feature_on?(:limit_short_description) }

  delegate :in_dispute, to: :order_details, prefix: true
  delegate :requiring_approval, :requiring_approval_by_type, to: :products, prefix: true

  scope :active, :conditions => { :is_active => true }
  scope :sorted, order: :name

  def self.cross_facility
    @@cross_facility ||=
      new(url_name: "all", name: "Cross-Facility", abbreviation: "ALL")
  end

  def self.ids_from_urls(urls)
    where("url_name in (?)", urls).select(:id).map(&:id)
  end

  def self.urls_from_ids(ids)
    where("id in (?)", ids).select(:url_name).map(&:url_name)
  end
  def destroy
    # TODO: can you ever delete a facility? Currently no.
    # super
  end

  def description
    self[:description].html_safe if self[:description]
  end

  def to_param
    if errors[:url_name].empty?
      url_name
    else
      url_name_was
    end
  end

  def status_string
    is_active? ? 'Active' : 'Inactive'
  end

  def order_notification_email
    #TODO: generate an email address to send the order notifications to
    nil
  end

  def has_contact_info?
    address || phone_number || fax_number || email
  end

  def has_pending_journals?
    pending_facility_ids = Journal.facility_ids_with_pending_journals
    if cross_facility?
      pending_facility_ids.any?
    else
      pending_facility_ids.member?(self.id)
    end
  end

  def cross_facility?
    eql? self.class.cross_facility
  end

  def single_facility?
    !cross_facility?
  end

  def to_s
    "#{name} (#{abbreviation})"
  end

  def problem_non_reservation_order_details
    complete_problem_order_details.non_reservations
  end

  def problem_reservation_order_details
    complete_problem_order_details.reservations
  end

  private

  def complete_problem_order_details
    order_details.problem_orders.complete
  end

  def set_journal_mask
    f = Facility.find(:all, :limit => 1, :order => 'journal_mask DESC').first
    if f && f.journal_mask.match(/^C(\d{2})$/)
      self.journal_mask = sprintf("C%02d", $1.to_i + 1)
    else
      self.journal_mask = 'C01'
    end
  end
end

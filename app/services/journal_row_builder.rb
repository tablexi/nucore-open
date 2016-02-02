require "set"

class JournalRowBuilder

  attr_reader :order_details, :journal, :journal_rows, :errors,
    :recharge_enabled, :product_recharges, :journaled_facility_ids

  # Minimal initialization.
  def initialize(order_details, journal)
    @journal = journal
    @order_details = order_details
    @recharge_enabled = SettingsHelper.feature_on?(:recharge_accounts)
    reset
  end

  # Idempotent method that builds an array of new journal_rows. Also adds to
  # errors if any problems occur. Does not save anything to the database.
  # Returns self.
  def build
    reset
    order_details.each do |order_detail|
      account = order_detail.account
      validate_order_detail_unjournaled(order_detail)
      validate_facility_can_journal(order_detail)
      validate_account(order_detail)
      new_journal_rows = order_detail_to_journal_rows(order_detail)
      update_product_recharges(order_detail)
      @journal_rows.concat(new_journal_rows)
    end
    add_journal_rows_from_product_recharges
    self
  end

  # Convenience method. Best to use this incase errors ends changing to a
  # hash of arrays keyed by order_detail id.
  def valid?
    errors.present?
  end

  # Set an array of facility_ids with pending journals
  def pending_facility_ids
    @pending_facility_ids ||= Journal.facility_ids_with_pending_journals
  end

  private

  # Reset instance variables both on initialize and build.
  def reset
    @errors = []
    @journal_rows = []
    @journaled_facility_ids = Set.new
    @pending_facility_ids = nil
    @product_recharges = {}
  end

  # Validate the order_detail hasn't already been journaled
  def validate_order_detail_unjournaled(order_detail)
    if order_detail.journal_id.present?
      @errors << "#{order_detail} is already journaled in journal #{order_detail.journal_id}"
    end
  end

  # Validate the order_details's facility doesn't currently have a pending
  # journal.
  def validate_facility_can_journal(order_detail)
    facility_id = order_detail.order.facility_id
    unless journaled_facility_ids.include?(facility_id)
      if pending_facility_ids.include?(facility_id)
        @errors << I18n.t(
          "activerecord.errors.models.journal.pending_overlap",
          label: order_detail.to_s,
          facility: Facility.find(facility_id)
        )
      else
        journaled_facility_ids.add(facility_id)
      end
    end
  end

  # Validate each journal_row account. This is necessary because an order_detail
  # may generate multiple journal_rows with different accounts, and we need to
  # validate them all.
  #
  # TODO: we may need to add a validator factory for split_accounts. Otherwise
  # we assume a product account can not be a split account.
  def validate_account(order_detail)
    account = order_detail.account
    begin
      ValidatorFactory.instance(account.account_number, order_detail.product.account).account_is_open!(order_detail.fulfilled_at)
    rescue ValidatorError => e
      @errors << I18n.t(
        "activerecord.errors.models.journal.invalid_account",
        account_number: account.account_number_to_s,
        validation_error: e.message
      )
    end
  end

  # Given an order detail, return an array of one or more new JournalRow
  # objects.
  def order_detail_to_journal_rows(order_detail)
    convert = converter_object(order_detail.account)
    convert.from_order_detail(order_detail, journal)
  end

  # Given a product and total, return an array of one or more new JournalRow
  # objects.
  def product_to_journal_rows(product, total)
    convert = converter_object(nil)
    convert.from_product(product, total, journal)
  end

  # Returns a JournalRowConverter object that will convert provided objects
  # to an array of one or more journal_row instances.
  def converter_object(account)
    account_type = account.class.to_s.underscore
    begin
      Settings.journal_row.converters[account_type].constantize
    rescue NameError
      Settings.journal_row.converters["default"].constantize
    end
  end

  # If recharge_enabled, then sum up the product_recharges by product so each
  # product recharge can later be added as an additional journal_row.
  #
  # TODO: reused existing logic. Instead it might be better to assign a
  # {product: order_detail.product, amount: 0} hash for each product_recharges
  # array element.
  def update_product_recharges(order_detail)
    if recharge_enabled
      product_id = order_detail.product_id
      product_recharges[product_id] ||= 0
      product_recharges[product_id] += order_detail.total
    end
  end

  # When you’re creating a journal, for a single order detail you’ll have one
  # or more journal rows for money coming out of an account and one journal row
  # for the money going into the recharge account. One journal row is positive
  # and one is negative. Only builds journal_rows if the recharge_enabled
  # feature is enabled.
  def add_journal_rows_from_product_recharges
    product_recharges.each_pair do |product_id, total|
      product = Product.find(product_id)
      new_journal_rows = product_to_journal_rows(product, total)
      @journal_rows.concat(new_journal_rows)
    end
  end

end

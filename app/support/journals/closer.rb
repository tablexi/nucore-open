class Journals::Closer
  attr_reader :journal, :params

  def initialize(journal, params)
    @journal = journal
    # It's like strong_params...
    @params = params.slice(:reference, :description, :updated_by)
  end

  def perform(status)
    rollback_on_fail do
      case status
      when 'failed'
        mark_as_failed
      when 'succeeded_errors'
        mark_as_succeeded_with_errors
      when 'succeeded'
        mark_as_succeeded
      else
        journal.errors.add(:base, I18n.t('controllers.facility_journals.update.error.status'))
        false
      end
    end
  end

  private

  def mark_as_failed
    # Oracle is sometimes not converting false to null
    false_value = NUCore::Database.boolean(false)
    if journal.update_attributes(params.merge(is_successful: false_value))
      # remove all the orders from the journal
      journal.order_details.update_all(journal_id: nil)
      true
    else
      false
    end
  end

  def update_all?
    false
  end

  def mark_as_succeeded_with_errors
    journal.update_attributes(params.merge(is_successful: true))
  end

  def mark_as_succeeded
    if journal.update_attributes(params.merge(is_successful: true))
      reconciled_status = OrderStatus.reconciled.first
      if update_all?
        journal.order_details.update_all(state: 'reconciled', order_status_id: reconciled_status.id)
      else
        journal.order_details.each do |od|
          od.change_status!(reconciled_status)
        end
      end
      true
    else
      false
    end
  end

  def rollback_on_fail
    Journal.transaction requires_new: true do
      if yield
        true
      else
        raise ActiveRecord::Rollback
      end
    end
  end
end

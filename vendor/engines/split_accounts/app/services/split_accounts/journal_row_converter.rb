module SplitAccounts

  # TODO: use an instance rather than a class service object and store journal
  # and possibly order_detail
  class JournalRowConverter < ::JournalRowConverter

    # Returns an array of generated journal_rows given a single order_detail.
    def self.from_order_detail(order_detail, journal = nil)
      splits = order_detail.account.splits
      journal_rows = splits.map { |split| split_to_journal_row(order_detail, split, journal) }
      apply_remainder(splits, journal_rows)
    end

    # TODO: ensure `account: order_detail.product.account` no longer necessary
    def self.split_to_journal_row(order_detail, split, journal)
      {
        account: split.subaccount,
        amount: floored_split_amount(order_detail.total, split.percent),
        description: order_detail.long_description,
        order_detail_id: order_detail.id,
        journal_id: journal.try(:id),
        extra_penny: split.extra_penny,
      }
    end

    # TODO: rename `extra_penny` to `remainder`
    # TODO: test negative values as well
    def self.apply_remainder(total, journal_rows)
      floored_total = journal_rows.reduce(0) { |sum, journal_row| sum + journal_row.amount }
      adjustment = total - floored_total
      index = journal_rows.find_index { |row| row.extra_penny }
      journal_rows[index][:amount] += adjustment
      journal_rows
    end

    def self.floored_split_amount(total, percent)
      return 0 if percent == 0
      cents = (total*100) * (percent/100)
      cents.floor / 100
    end

  end
end

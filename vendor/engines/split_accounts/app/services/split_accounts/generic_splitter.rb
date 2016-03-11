module SplitAccounts
  class GenericSplitter
    attr_reader :original_object, :split_objects, :attributes_to_split
    def initialize(object, account, attributes_to_split)
      @original_object = object
      @account = account
      @attributes_to_split = attributes_to_split
    end

    def split(&block)
      @split_objects = @account.splits.map { |split| build_split_object(split, &block) }
      apply_remainders
      @split_objects
    end

    def build_split_object(split, &block)
      split_object = block.call(original_object.dup)

      attributes_to_split.each do |attr|
        split_object.public_send "#{attr}=", floored_amount(split.percent, original_object.public_send(attr))
      end

      split_object
    end

    private

    def apply_remainders
      index = find_remainder_index
      attributes_to_split.each { |attr| apply_remainder(attr, index) }
    end

    def apply_remainder(attr, index)
      return if original_object.send(attr).blank?
      adjustment = original_object.send(attr) - floored_total(split_objects, attr)
      new_value = split_objects[index].send(attr) + adjustment
      split_objects[index].send "#{attr}=", new_value
    end

    def find_remainder_index
      split_objects.find_index { |item| item.split.extra_penny? }
    end

    def floored_total(items, attr)
      items.reduce(BigDecimal(0)) { |sum, item| sum + item.send(attr) }
    end

    def floored_amount(percent, value)
      return BigDecimal(0) if percent == 0 || value.blank?
      amount = BigDecimal(value) * BigDecimal(percent) / 100
      amount.floor(2)
    end

  end
end

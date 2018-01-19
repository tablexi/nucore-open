module SplitAccounts

  class OrderDetailListTransformer

    attr_reader :order_details

    def initialize(order_details = [])
      @order_details = order_details
    end

    def perform(options = {})
      options ||= {} # in case it comes in as nil

      nested_map(order_details) do |order_detail|
        if order_detail.account.try(:splits).try(:present?)
          SplitAccounts::OrderDetailSplitter.new(order_detail, split_time_data: options[:time_data]).split
        else
          order_detail
        end
      end
    end

    private

    # Wraps a lazy enumerator with another enumerator so that if the block returns
    # an Array, each value of that array gets yielded.
    # Example:
    # output = nested_map(1..Float::Infinity) do |i|
    #   if i.even?
    #     [i, i]
    #   else
    #     i
    #   end
    # end
    #
    # > output.take(5).to_a
    # => [1, 2, 2, 3, 4]
    def nested_map(enumerable)
      Enumerator::Lazy.new(enumerable.to_enum) do |yielder, *values|
        results = yield(*values)
        Array(results).each do |val|
          yielder << val
        end
      end
    end

  end

end

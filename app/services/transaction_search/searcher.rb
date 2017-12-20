module TransactionSearch

  class Searcher

    # Do not modify this directly. Use TransactionSearch.register instead.
    cattr_accessor(:default_searchers) do
      [
        :facilities,
        :accounts,
        :products,
        :account_owners,
        :order_statuses,
        :date_ranges,
      ]
    end

    # Expects an array of `TransactionSearch::BaseSearcher`s
    def initialize(*searchers)
      searchers = self.class.default_searchers if searchers.blank?

      @searchers = Array(searchers)
    end

    def search(order_details, params)
      @searchers.reduce(Results.new(order_details)) do |results, searcher_class|
        searcher = searcher_class.new(results.order_details)

        search_params = params[searcher_class.key.to_sym]
        search_params = Array(search_params).reject(&:blank?) unless searcher.multipart?

        # TODO: Collapse optimized into search within the searchers. We have not
        # done it yet because the TransactionSearch controller concern still relies
        # on the API being split into two calls. Once that is gone, these can be
        # collapsed within each BaseSearcher.
        non_optimized = searcher.search(search_params)
        optimized_order_details = searcher_class.new(non_optimized).optimized

        # Options should not be restricted, they should search over the full order details
        option_searcher = searcher_class.new(order_details)

        Results.new(
          optimized_order_details,
          results.options + [option_searcher],
        )
      end
    end

    class Results

      attr_reader :order_details

      def initialize(order_details, search_options = [])
        @order_details = order_details
        @search_options = search_options.freeze
      end

      def options
        @search_options.dup
      end

    end

  end

end

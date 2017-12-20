module TransactionSearch

  class Searcher

    # Expects an array of `TransactionSearch::BaseSearcher`s
    def initialize(*searchers)
      @searchers = Array(searchers)
    end

    def search(order_details, params)
      @searchers.reduce(Results.new(order_details)) do |results, searcher_class|
        searcher = searcher_class.new(results.order_details)

        # TODO: Collapse optimized into search within the searchers
        non_optimized = searcher.search(Array(params[searcher_class.key.to_sym]).reject(&:blank?))
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

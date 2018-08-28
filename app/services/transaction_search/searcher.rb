# frozen_string_literal: true

module TransactionSearch

  class Searcher

    # Do not modify this array directly. Use `TransactionSearch.register` instead.
    # There is some additional setup that needs to happen (adding an atr_accessor
    # to SearchForm) that `register` handles.
    cattr_accessor(:default_searchers) do
      [
        TransactionSearch::FacilitySearcher,
        TransactionSearch::AccountSearcher,
        TransactionSearch::ProductSearcher,
        TransactionSearch::AccountOwnerSearcher,
        TransactionSearch::OrderStatusSearcher,
        TransactionSearch::DateRangeSearcher,
      ]
    end

    # Prefer `TransactionSearch.register_optimizer` rather than modifying this
    # directly in order to maintain API consistency with `default_searchers`.
    cattr_accessor(:optimizers) do
      [
        TransactionSearch::NPlusOneOptimizer,
      ]
    end

    # Shorthand method if you only want the default searchers
    def self.search(order_details, params)
      new.search(order_details, params)
    end

    # Expects an array of `TransactionSearch::BaseSearcher`s
    def initialize(*searchers)
      searchers = self.class.default_searchers if searchers.blank?

      @searchers = Array(searchers)
    end

    def search(order_details, params)
      order_details = add_global_optimizations(order_details)

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

    private

    def add_global_optimizations(order_details)
      optimizers.reduce(order_details) do |current, optimizer|
        optimizer.new(current).optimize
      end
    end

    class Results

      attr_reader :order_details

      # Return an array of options for a given key
      delegate :[], to: :to_options_by_searcher

      def initialize(order_details, search_options = [])
        @order_details = order_details
        @search_options = search_options.freeze
      end

      def options
        @search_options.dup
      end

      def to_options_by_searcher
        @to_h ||= options.each_with_object({}) do |searcher, hash|
          hash[searcher.key] = searcher.options
        end
      end

    end

  end

end

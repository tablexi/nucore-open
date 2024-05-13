# frozen_string_literal: true

module TransactionSearch

  class BaseSearcher

    attr_reader :order_details

    def self.key
      to_s.sub(/\ATransactionSearch::/, "").sub(/Searcher\z/, "").pluralize.underscore
    end

    def initialize(order_details)
      @order_details = order_details
    end

    def key
      self.class.key
    end

    def multipart?
      false
    end

    def label_method
      nil
    end

    def value_method(_option)
      nil
    end

    def label
      nil
    end

    # `item` will be one element of the collection
    def data_attrs(_item)
      {}
    end

    def options
      raise NotImplementedError
    end

    def search(_params)
      raise NotImplementedError
    end

  end

end
